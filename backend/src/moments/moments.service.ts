import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  Moment,
  MomentDocument,
  MomentStatus,
  normalizeParticipants,
} from '../database/schemas/moment.schema';
import { User, UserDocument } from '../database/schemas/user.schema';
import {
  MomentShortcut,
  MomentShortcutDocument,
} from '../database/schemas/moment-shortcut.schema';
import { ConversationsService } from '../conversations/conversations.service';
import { MessagesService } from '../messages/messages.service';
import { UsersService } from '../users/users.service';
import { MessageType } from '../database/schemas/message.schema';
import { SendMomentDto } from './dto/send-moment.dto';
import { CreateShortcutDto, UpdateShortcutDto } from './dto/shortcut.dto';

@Injectable()
export class MomentsService {
  constructor(
    @InjectModel(Moment.name) private momentModel: Model<MomentDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(MomentShortcut.name)
    private shortcutModel: Model<MomentShortcutDocument>,
    @Inject(forwardRef(() => ConversationsService))
    private conversationsService: ConversationsService,
    @Inject(forwardRef(() => MessagesService))
    private messagesService: MessagesService,
    private usersService: UsersService,
  ) {}

  /**
   * Starts a new Moment between two users.
   * If an active Moment already exists, returns it idempotently without creating a duplicate.
   * If the previous Moment expired, creates a fresh NEW Moment at count 0.
   */
  async startMoment(userId: string, targetUserId: string) {
    if (!targetUserId || !Types.ObjectId.isValid(targetUserId)) {
      throw new BadRequestException('Invalid target user ID');
    }

    if (userId === targetUserId) {
      throw new BadRequestException('Cannot start a Moment with yourself');
    }

    const targetUser = await this.userModel.findById(targetUserId);
    if (!targetUser) {
      throw new NotFoundException('Target user not found');
    }

    const { participantA, participantB, participants } = normalizeParticipants(
      userId,
      targetUserId,
    );

    const now = new Date();

    // Check for an existing active or expiring soon Moment
    const existing = await this.momentModel.findOne({
      participantA,
      participantB,
      status: { $in: [MomentStatus.ACTIVE, MomentStatus.EXPIRING_SOON] },
    });

    if (existing) {
      // Check if it has expired in real-time
      if (now.getTime() >= existing.expiresAt.getTime()) {
        existing.status = MomentStatus.EXPIRED;
        await existing.save();
      } else {
        // Active Moment already exists; return it without modification
        return this.formatMomentResponse(existing, userId);
      }
    }

    // Previous Moment expired or does not exist: create a fresh NEW Moment starting at 0
    const expiresAt = new Date(now.getTime() + 24 * 60 * 60 * 1000); // 24-hour rolling window

    const newMoment = await this.momentModel.create({
      participantA,
      participantB,
      participants,
      currentCount: 0,
      status: MomentStatus.ACTIVE,
      participantAInteractedAt: null,
      participantBInteractedAt: null,
      currentWindowStartedAt: now,
      lastCompletedAt: null,
      expiresAt,
      startedAt: now,
    });

    return this.formatMomentResponse(newMoment, userId);
  }

  /**
   * Records an interaction between sender and recipient.
   * Uses rolling 24-hour window logic:
   * - Both participants must interact within the active 24-hour window to complete the Moment.
   * - Count increments by exactly 1 per completed window.
   * - Multiple messages from the same participant do NOT extend the timer or increment count.
   * - Atomically safe against simultaneous messages.
   */
  async recordInteraction(senderId: string, recipientId: string) {
    const { participantA, participantB } = normalizeParticipants(
      senderId,
      recipientId,
    );

    const now = new Date();

    const moment = await this.momentModel.findOne({
      participantA,
      participantB,
      status: { $in: [MomentStatus.ACTIVE, MomentStatus.EXPIRING_SOON] },
    });

    if (!moment) {
      return null;
    }

    // Check if Moment has expired
    if (now.getTime() >= moment.expiresAt.getTime()) {
      moment.status = MomentStatus.EXPIRED;
      await moment.save();
      return null;
    }

    const isSenderA = moment.participantA.toString() === senderId;
    const windowStart = moment.currentWindowStartedAt || moment.startedAt;

    const senderInteractedAt = isSenderA
      ? moment.participantAInteractedAt
      : moment.participantBInteractedAt;

    const otherInteractedAt = isSenderA
      ? moment.participantBInteractedAt
      : moment.participantAInteractedAt;

    // Check if the other participant has already interacted within the current window
    const otherHasInteractedInWindow =
      otherInteractedAt && otherInteractedAt.getTime() >= windowStart.getTime();

    // Check if sender has already interacted in this window
    const senderHasInteractedInWindow =
      senderInteractedAt && senderInteractedAt.getTime() >= windowStart.getTime();

    if (otherHasInteractedInWindow) {
      if (senderHasInteractedInWindow) {
        // Both have already completed this window; repeated messages do not increment or extend timer
        return moment;
      }

      // Other participant interacted, and this is sender's first interaction in the window:
      // ATOMIC COMPLETION! Increment currentCount, start new 24h window, reset completion.
      const updated = await this.momentModel.findOneAndUpdate(
        {
          _id: moment._id,
          currentWindowStartedAt: moment.currentWindowStartedAt, // Guard against concurrent race condition
        },
        {
          $inc: { currentCount: 1 },
          $set: {
            lastCompletedAt: now,
            currentWindowStartedAt: now,
            expiresAt: new Date(now.getTime() + 24 * 60 * 60 * 1000),
            status: MomentStatus.ACTIVE,
            ...(isSenderA
              ? { participantAInteractedAt: now }
              : { participantBInteractedAt: now }),
          },
        },
        { new: true },
      );

      return updated || (await this.momentModel.findById(moment._id));
    } else {
      // Other participant has not yet interacted in this window.
      // Update sender's timestamp without extending the expiration timer or incrementing count.
      const updateFields: any = {};
      if (isSenderA) {
        updateFields.participantAInteractedAt = now;
      } else {
        updateFields.participantBInteractedAt = now;
      }

      await this.momentModel.findByIdAndUpdate(moment._id, {
        $set: updateFields,
      });

      return moment;
    }
  }

  /**
   * Dispatches a single captured Moment media asset to multiple recipients independently.
   * Reuses the existing conversation lookup and messaging pipeline.
   * Does NOT refresh or extend the 24-hour timer on multiple sends.
   * Independent Moment relationships are created/updated per recipient.
   */
  async sendMoment(userId: string, dto: SendMomentDto) {
    if (!dto.mediaUrl) {
      throw new BadRequestException('mediaUrl is required');
    }

    if (!dto.recipientIds || dto.recipientIds.length === 0) {
      throw new BadRequestException('At least one recipient must be selected');
    }

    const uniqueRecipients = [...new Set(dto.recipientIds.filter((id) => id !== userId))];
    if (uniqueRecipients.length === 0) {
      throw new BadRequestException('No valid recipients provided');
    }

    const results: any[] = [];

    for (const recipientId of uniqueRecipients) {
      if (!Types.ObjectId.isValid(recipientId)) {
        results.push({
          recipientId,
          success: false,
          error: 'Invalid recipient ID',
        });
        continue;
      }

      try {
        const isBlocked = await this.usersService.isUserBlocked(userId, recipientId);
        if (isBlocked) {
          results.push({
            recipientId,
            success: false,
            error: 'User is blocked',
          });
          continue;
        }

        // 1. Ensure conversation exists using existing conversation service
        const conversation = await this.conversationsService.getOrCreateOneToOne(
          userId,
          recipientId,
        );

        // 2. Ensure Moment relationship exists between the pair
        await this.startMoment(userId, recipientId);

        // 3. Dispatch media message using existing messages pipeline
        // (This triggers recordInteraction internally preserving rolling 24h rules)
        await this.messagesService.sendMessage(
          conversation._id.toString(),
          userId,
          {
            type: MessageType.IMAGE,
            content: dto.caption || 'Sent a Moment',
            mediaUrl: dto.mediaUrl,
            mediaMetadata: dto.filter ? { filter: dto.filter } : undefined,
          },
        );

        // 4. Retrieve independent Moment state for this recipient
        const updatedMoment = await this.getMomentWithUser(userId, recipientId);

        results.push({
          recipientId,
          success: true,
          moment: updatedMoment,
        });
      } catch (err: any) {
        results.push({
          recipientId,
          success: false,
          error: err.message || 'Failed to deliver Moment',
        });
      }
    }

    return {
      success: results.some((r) => r.success),
      mediaUrl: dto.mediaUrl,
      results,
    };
  }

  /**
   * Retrieves all active Moments for the given user with friend details and remaining hours.
   */
  async getUserMoments(userId: string) {
    const userObjectId = new Types.ObjectId(userId);
    const now = new Date();

    const moments = await this.momentModel
      .find({
        participants: userObjectId,
        status: { $in: [MomentStatus.ACTIVE, MomentStatus.EXPIRING_SOON] },
      })
      .populate('participants', 'username displayName profilePhoto isOnline lastSeen')
      .exec();

    const activeList: any[] = [];

    for (const moment of moments) {
      if (now.getTime() >= moment.expiresAt.getTime()) {
        moment.status = MomentStatus.EXPIRED;
        await moment.save();
        continue;
      }

      // Check if approaching expiry (under 3 hours left)
      const hoursRemaining =
        (moment.expiresAt.getTime() - now.getTime()) / (1000 * 60 * 60);

      if (hoursRemaining <= 3 && moment.status !== MomentStatus.EXPIRING_SOON) {
        moment.status = MomentStatus.EXPIRING_SOON;
        await moment.save();
      }

      activeList.push(this.formatMomentResponse(moment, userId));
    }

    return activeList;
  }

  /**
   * Retrieves an active Moment with a specific user if it exists.
   */
  async getMomentWithUser(userId: string, targetUserId: string) {
    const { participantA, participantB } = normalizeParticipants(
      userId,
      targetUserId,
    );

    const now = new Date();

    const moment = await this.momentModel
      .findOne({
        participantA,
        participantB,
        status: { $in: [MomentStatus.ACTIVE, MomentStatus.EXPIRING_SOON] },
      })
      .populate('participants', 'username displayName profilePhoto isOnline lastSeen')
      .exec();

    if (!moment) {
      return null;
    }

    if (now.getTime() >= moment.expiresAt.getTime()) {
      moment.status = MomentStatus.EXPIRED;
      await moment.save();
      return null;
    }

    return this.formatMomentResponse(moment, userId);
  }

  /**
   * Ends/removes a Moment.
   */
  async endMoment(momentId: string, userId: string) {
    if (!Types.ObjectId.isValid(momentId)) {
      throw new BadRequestException('Invalid Moment ID');
    }

    const moment = await this.momentModel.findById(momentId);
    if (!moment) {
      throw new NotFoundException('Moment not found');
    }

    const isParticipant = moment.participants.some(
      (p) => p.toString() === userId,
    );
    if (!isParticipant) {
      throw new ForbiddenException('Access denied');
    }

    moment.status = MomentStatus.EXPIRED;
    await moment.save();

    return { message: 'Moment ended successfully', id: moment._id.toString() };
  }

  // --- SHORTCUTS METHODS ---

  async getShortcuts(userId: string) {
    const shortcuts = await this.shortcutModel
      .find({ ownerId: new Types.ObjectId(userId) })
      .populate('contactIds', 'username displayName profilePhoto isOnline lastSeen bio')
      .sort({ createdAt: -1 })
      .exec();

    return shortcuts.map((s) => this.formatShortcutResponse(s));
  }

  async createShortcut(userId: string, dto: CreateShortcutDto) {
    if (!dto.name || !dto.name.trim()) {
      throw new BadRequestException('Shortcut name is required');
    }

    const validatedContactIds = await this.validateShortcutContacts(
      userId,
      dto.contactIds || [],
    );

    const shortcut = await this.shortcutModel.create({
      ownerId: new Types.ObjectId(userId),
      name: dto.name.trim(),
      emoji: dto.emoji || '✨',
      contactIds: validatedContactIds,
    });

    const populated = await this.shortcutModel
      .findById(shortcut._id)
      .populate('contactIds', 'username displayName profilePhoto isOnline lastSeen bio')
      .exec();

    return this.formatShortcutResponse(populated);
  }

  async updateShortcut(
    userId: string,
    shortcutId: string,
    dto: UpdateShortcutDto,
  ) {
    if (!Types.ObjectId.isValid(shortcutId)) {
      throw new BadRequestException('Invalid shortcut ID');
    }

    const shortcut = await this.shortcutModel.findOne({
      _id: new Types.ObjectId(shortcutId),
      ownerId: new Types.ObjectId(userId),
    });

    if (!shortcut) {
      throw new NotFoundException('Shortcut not found');
    }

    if (dto.name !== undefined) {
      if (!dto.name.trim()) {
        throw new BadRequestException('Shortcut name cannot be empty');
      }
      shortcut.name = dto.name.trim();
    }

    if (dto.emoji !== undefined) {
      shortcut.emoji = dto.emoji;
    }

    if (dto.contactIds !== undefined) {
      shortcut.contactIds = await this.validateShortcutContacts(
        userId,
        dto.contactIds,
      );
    }

    await shortcut.save();

    const populated = await this.shortcutModel
      .findById(shortcut._id)
      .populate('contactIds', 'username displayName profilePhoto isOnline lastSeen bio')
      .exec();

    return this.formatShortcutResponse(populated);
  }

  async deleteShortcut(userId: string, shortcutId: string) {
    if (!Types.ObjectId.isValid(shortcutId)) {
      throw new BadRequestException('Invalid shortcut ID');
    }

    const result = await this.shortcutModel.deleteOne({
      _id: new Types.ObjectId(shortcutId),
      ownerId: new Types.ObjectId(userId),
    });

    if (result.deletedCount === 0) {
      throw new NotFoundException('Shortcut not found');
    }

    return { success: true, message: 'Shortcut deleted successfully' };
  }

  private async validateShortcutContacts(
    userId: string,
    contactIds: string[],
  ): Promise<Types.ObjectId[]> {
    const validIds: Types.ObjectId[] = [];
    const uniqueIds = [...new Set(contactIds.filter((id) => id && id !== userId))];

    for (const id of uniqueIds) {
      if (Types.ObjectId.isValid(id)) {
        const userExists = await this.userModel.exists({ _id: new Types.ObjectId(id) });
        if (userExists) {
          const isBlocked = await this.usersService.isUserBlocked(userId, id);
          if (!isBlocked) {
            validIds.push(new Types.ObjectId(id));
          }
        }
      }
    }

    return validIds;
  }

  private formatShortcutResponse(shortcut: any) {
    const contacts = (shortcut.contactIds || [])
      .filter((c: any) => c && c._id)
      .map((c: any) => ({
        id: c._id.toString(),
        username: c.username,
        displayName: c.displayName,
        profilePhoto: c.profilePhoto,
        isOnline: c.isOnline,
        lastSeen: c.lastSeen,
        bio: c.bio,
      }));

    return {
      id: shortcut._id.toString(),
      name: shortcut.name,
      emoji: shortcut.emoji || '✨',
      contactIds: contacts.map((c: any) => c.id),
      contacts,
      createdAt: shortcut.createdAt,
      updatedAt: shortcut.updatedAt,
    };
  }

  private formatMomentResponse(moment: any, currentUserId: string) {
    const now = new Date();
    const expiresAt = new Date(moment.expiresAt);
    const msRemaining = Math.max(0, expiresAt.getTime() - now.getTime());
    const hoursRemaining = Math.round(msRemaining / (1000 * 60 * 60));

    const isSenderA = moment.participantA.toString() === currentUserId;
    const windowStart = moment.currentWindowStartedAt || moment.startedAt;

    const myLastInteraction = isSenderA
      ? moment.participantAInteractedAt
      : moment.participantBInteractedAt;

    const hasInteractedInCurrentWindow =
      myLastInteraction &&
      new Date(myLastInteraction).getTime() >= new Date(windowStart).getTime();

    // Find the other participant
    let friendUser: any = null;
    if (moment.participants && moment.participants.length > 0) {
      friendUser = moment.participants.find(
        (p: any) => p._id && p._id.toString() !== currentUserId,
      );
    }

    return {
      id: moment._id.toString(),
      currentCount: moment.currentCount,
      status: moment.status,
      startedAt: moment.startedAt,
      currentWindowStartedAt: moment.currentWindowStartedAt,
      lastCompletedAt: moment.lastCompletedAt,
      expiresAt: moment.expiresAt,
      hoursRemaining,
      isExpiringSoon: hoursRemaining <= 3 && moment.status !== MomentStatus.EXPIRED,
      hasInteractedInCurrentWindow: !!hasInteractedInCurrentWindow,
      friend: friendUser
        ? {
            id: friendUser._id.toString(),
            displayName: friendUser.displayName,
            username: friendUser.username,
            profilePhoto: friendUser.profilePhoto,
            isOnline: friendUser.isOnline,
            lastSeen: friendUser.lastSeen,
          }
        : null,
    };
  }
}
