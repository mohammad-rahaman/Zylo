import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Conversation, ConversationDocument } from '../database/schemas/conversation.schema';
import { Message, MessageDocument } from '../database/schemas/message.schema';
import { User, UserDocument } from '../database/schemas/user.schema';
import { UsersService } from '../users/users.service';

@Injectable()
export class ConversationsService {
  constructor(
    @InjectModel(Conversation.name) private conversationModel: Model<ConversationDocument>,
    @InjectModel(Message.name) private messageModel: Model<MessageDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    private usersService: UsersService,
  ) {}

  async getOrCreateOneToOne(currentUserId: string, participantId: string) {
    if (currentUserId === participantId) {
      throw new BadRequestException('Cannot start a conversation with yourself');
    }

    if (!Types.ObjectId.isValid(participantId)) {
      throw new BadRequestException('Invalid participant ID');
    }

    const isBlocked = await this.usersService.isUserBlocked(currentUserId, participantId);
    if (isBlocked) {
      throw new ForbiddenException('Cannot create conversation with a blocked user');
    }

    const participant = await this.userModel.findById(participantId);
    if (!participant) {
      throw new NotFoundException('Participant does not exist');
    }

    const currentUserObjId = new Types.ObjectId(currentUserId);
    const participantObjId = new Types.ObjectId(participantId);

    // Look for existing 1-on-1 conversation
    let conversation = await this.conversationModel
      .findOne({
        participants: { $all: [currentUserObjId, participantObjId], $size: 2 },
      })
      .populate('participants', 'username displayName email profilePhoto isOnline lastSeen bio')
      .populate('lastMessage')
      .exec();

    if (!conversation) {
      conversation = await this.conversationModel.create({
        participants: [currentUserObjId, participantObjId],
        lastMessageAt: new Date(),
        unreadCounts: new Map<string, number>([
          [currentUserId, 0],
          [participantId, 0],
        ]),
      });

      conversation = await this.conversationModel
        .findById(conversation._id)
        .populate('participants', 'username displayName email profilePhoto isOnline lastSeen bio')
        .populate('lastMessage')
        .exec();
    }

    const convObj = (conversation as any).toObject ? (conversation as any).toObject() : conversation;
    const otherParticipant = convObj.participants?.find(
      (p: any) => (p._id ? p._id.toString() : p.id ? p.id.toString() : p.toString()) !== currentUserId,
    );
    const unreadCount =
      convObj.unreadCounts instanceof Map
        ? convObj.unreadCounts.get(currentUserId) || 0
        : (convObj.unreadCounts && (convObj.unreadCounts as any)[currentUserId]) || 0;

    let mappedOther: any = otherParticipant;
    if (mappedOther && typeof mappedOther === 'object' && mappedOther._id) {
      mappedOther = {
        ...mappedOther,
        id: mappedOther._id.toString(),
      };
    }

    return {
      ...convObj,
      id: convObj._id.toString(),
      otherParticipant: mappedOther,
      unreadCount,
    };
  }

  async getUserConversations(currentUserId: string) {
    const userObjId = new Types.ObjectId(currentUserId);

    const conversations = await this.conversationModel
      .find({ participants: userObjId })
      .sort({ lastMessageAt: -1, updatedAt: -1 })
      .populate('participants', 'username displayName email profilePhoto isOnline lastSeen bio')
      .populate({
        path: 'lastMessage',
        select: 'senderId type content mediaUrl status createdAt',
      })
      .lean()
      .exec();

    return conversations.map((conv) => {
      const otherParticipant = conv.participants?.find(
        (p: any) => (p._id ? p._id.toString() : p.id ? p.id.toString() : p.toString()) !== currentUserId,
      );

      // Extract unread count for current user
      const unreadCount =
        conv.unreadCounts instanceof Map
          ? conv.unreadCounts.get(currentUserId) || 0
          : (conv.unreadCounts && (conv.unreadCounts as any)[currentUserId]) || 0;

      let mappedOther: any = otherParticipant;
      if (mappedOther && typeof mappedOther === 'object' && mappedOther._id) {
        mappedOther = {
          ...mappedOther,
          id: mappedOther._id.toString(),
        };
      }

      return {
        ...conv,
        id: conv._id.toString(),
        otherParticipant: mappedOther,
        unreadCount,
      };
    });
  }

  async getConversationById(id: string, currentUserId: string) {
    if (!Types.ObjectId.isValid(id)) {
      throw new BadRequestException('Invalid conversation ID');
    }

    const conv = await this.conversationModel
      .findById(id)
      .populate('participants', 'username displayName email profilePhoto isOnline lastSeen bio')
      .populate('lastMessage')
      .lean()
      .exec();

    if (!conv) {
      throw new NotFoundException('Conversation not found');
    }

    const isParticipant = conv.participants.some(
      (p: any) => (p._id ? p._id.toString() : p.id ? p.id.toString() : p.toString()) === currentUserId,
    );
    if (!isParticipant) {
      throw new ForbiddenException('Access denied: You are not a participant');
    }

    const otherParticipant = conv.participants?.find(
      (p: any) => (p._id ? p._id.toString() : p.id ? p.id.toString() : p.toString()) !== currentUserId,
    );

    let mappedOther: any = otherParticipant;
    if (mappedOther && typeof mappedOther === 'object' && mappedOther._id) {
      mappedOther = {
        ...mappedOther,
        id: mappedOther._id.toString(),
      };
    }

    return {
      ...conv,
      id: conv._id.toString(),
      otherParticipant: mappedOther,
    };
  }

  async deleteConversation(id: string, currentUserId: string) {
    if (!Types.ObjectId.isValid(id)) {
      throw new BadRequestException('Invalid conversation ID');
    }

    const conv = await this.conversationModel.findById(id);
    if (!conv) {
      throw new NotFoundException('Conversation not found');
    }

    const isParticipant = conv.participants.some(
      (p) => p.toString() === currentUserId,
    );
    if (!isParticipant) {
      throw new ForbiddenException('Access denied');
    }

    // Delete messages associated with conversation
    await this.messageModel.deleteMany({ conversationId: conv._id });
    await this.conversationModel.deleteOne({ _id: conv._id });

    return { success: true, message: 'Conversation deleted successfully' };
  }

  async updateLastMessage(
    conversationId: string,
    messageId: string,
    senderId: string,
    participants: string[],
  ) {
    const updateOps: any = {
      $set: {
        lastMessage: new Types.ObjectId(messageId),
        lastMessageAt: new Date(),
      },
      $inc: {},
    };

    // Increment unread count for other participants
    for (const pId of participants) {
      if (pId !== senderId) {
        updateOps.$inc[`unreadCounts.${pId}`] = 1;
      }
    }

    if (Object.keys(updateOps.$inc).length === 0) {
      delete updateOps.$inc;
    }

    await this.conversationModel.findByIdAndUpdate(conversationId, updateOps);
  }

  async resetUnread(conversationId: string, userId: string) {
    const key = `unreadCounts.${userId}`;
    await this.conversationModel.findByIdAndUpdate(conversationId, {
      $set: { [key]: 0 },
    });
  }
}
