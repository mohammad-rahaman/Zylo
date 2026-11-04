import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  InternalServerErrorException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Message, MessageDocument, MessageStatus } from '../database/schemas/message.schema';
import { Conversation, ConversationDocument } from '../database/schemas/conversation.schema';
import { UsersService } from '../users/users.service';
import { MomentsService } from '../moments/moments.service';
import { CreateMessageDto, UpdateMessageStatusDto } from './dto/create-message.dto';
import { GetMessagesQueryDto } from './dto/get-messages-query.dto';

@Injectable()
export class MessagesService {
  constructor(
    @InjectModel(Message.name) private messageModel: Model<MessageDocument>,
    @InjectModel(Conversation.name) private conversationModel: Model<ConversationDocument>,
    private usersService: UsersService,
    @Inject(forwardRef(() => MomentsService))
    private momentsService: MomentsService,
  ) {}

  async sendMessage(
    conversationId: string,
    senderId: string,
    dto: CreateMessageDto,
  ) {
    if (!Types.ObjectId.isValid(conversationId)) {
      throw new BadRequestException('Invalid conversation ID');
    }

    const conv = await this.conversationModel.findById(conversationId);
    if (!conv) {
      throw new NotFoundException('Conversation not found');
    }

    const isParticipant = conv.participants.some(
      (p) => p.toString() === senderId,
    );
    if (!isParticipant) {
      throw new ForbiddenException('Access denied');
    }

    // Check if any participant has blocked another
    for (const p of conv.participants) {
      const pId = p.toString();
      if (pId !== senderId) {
        const isBlocked = await this.usersService.isUserBlocked(senderId, pId);
        if (isBlocked) {
          throw new ForbiddenException('Cannot send message: User is blocked');
        }
      }
    }

    const newMessage = await this.messageModel.create({
      conversationId: new Types.ObjectId(conversationId),
      senderId: new Types.ObjectId(senderId),
      type: dto.type,
      content: dto.content || '',
      mediaUrl: dto.mediaUrl || '',
      mediaMetadata: dto.mediaMetadata,
      replyToId: dto.replyToId ? new Types.ObjectId(dto.replyToId) : undefined,
      status: MessageStatus.SENT,
      isDeleted: false,
    });

    // Update conversation lastMessage & increment unread counts
    const updateOps: any = {
      $set: {
        lastMessage: newMessage._id,
        lastMessageAt: newMessage.createdAt,
      },
      $inc: {},
    };

    for (const p of conv.participants) {
      const pId = p.toString();
      if (pId !== senderId) {
        updateOps.$inc[`unreadCounts.${pId}`] = 1;
        // Record Moment daily rolling interaction between sender and recipient
        try {
          await this.momentsService.recordInteraction(senderId, pId);
        } catch (_) {}
      }
    }

    if (Object.keys(updateOps.$inc).length === 0) {
      delete updateOps.$inc;
    }

    await this.conversationModel.findByIdAndUpdate(conv._id, updateOps);

    const populated = await this.messageModel
      .findById(newMessage._id)
      .populate('senderId', 'username displayName profilePhoto')
      .populate('replyToId')
      .lean()
      .exec();

    if (!populated) {
      throw new InternalServerErrorException('Failed to retrieve created message');
    }

    return {
      ...populated,
      id: (populated as any)._id.toString(),
    };
  }

  async getMessages(
    conversationId: string,
    currentUserId: string,
    query: GetMessagesQueryDto,
  ) {
    if (!Types.ObjectId.isValid(conversationId)) {
      throw new BadRequestException('Invalid conversation ID');
    }

    const conv = await this.conversationModel.findById(conversationId);
    if (!conv) {
      throw new NotFoundException('Conversation not found');
    }

    const isParticipant = conv.participants.some(
      (p) => p.toString() === currentUserId,
    );
    if (!isParticipant) {
      throw new ForbiddenException('Access denied');
    }

    const limit = query.limit || 30;
    const filter: any = {
      conversationId: new Types.ObjectId(conversationId),
    };

    // Cursor pagination using Mongo ObjectId (_id is strictly monotonically increasing by creation time)
    if (query.cursor && Types.ObjectId.isValid(query.cursor)) {
      filter._id = { $lt: new Types.ObjectId(query.cursor) };
    }

    // In-conversation text search
    if (query.search && query.search.trim().length > 0) {
      const searchClean = query.search.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      filter.content = new RegExp(searchClean, 'i');
    }

    // Fetch limit + 1 to determine if there are more items
    const rawMessages = await this.messageModel
      .find(filter)
      .sort({ _id: -1 })
      .limit(limit + 1)
      .populate('senderId', 'username displayName profilePhoto')
      .populate('replyToId')
      .lean()
      .exec();

    const hasMore = rawMessages.length > limit;
    const messages = hasMore ? rawMessages.slice(0, limit) : rawMessages;
    const nextCursor = messages.length > 0 ? messages[messages.length - 1]._id.toString() : null;

    // Reset unread count for this user
    await this.conversationModel.findByIdAndUpdate(conversationId, {
      $set: { [`unreadCounts.${currentUserId}`]: 0 },
    });

    return {
      messages: messages.map((m) => ({
        ...m,
        id: m._id.toString(),
      })),
      nextCursor,
      hasMore,
    };
  }

  async updateMessageStatus(
    messageId: string,
    currentUserId: string,
    dto: UpdateMessageStatusDto,
  ) {
    if (!Types.ObjectId.isValid(messageId)) {
      throw new BadRequestException('Invalid message ID');
    }

    const message = await this.messageModel.findById(messageId);
    if (!message) {
      throw new NotFoundException('Message not found');
    }

    message.status = dto.status;

    if (dto.status === MessageStatus.READ) {
      const alreadyRecorded = message.readBy.some(
        (r) => r.userId.toString() === currentUserId,
      );
      if (!alreadyRecorded) {
        message.readBy.push({
          userId: new Types.ObjectId(currentUserId) as any,
          readAt: new Date(),
        });
      }
    }

    await message.save();

    return {
      id: message._id.toString(),
      status: message.status,
      readBy: message.readBy,
    };
  }

  async deleteMessage(messageId: string, currentUserId: string) {
    if (!Types.ObjectId.isValid(messageId)) {
      throw new BadRequestException('Invalid message ID');
    }

    const message = await this.messageModel.findById(messageId);
    if (!message) {
      throw new NotFoundException('Message not found');
    }

    if (message.senderId.toString() !== currentUserId) {
      throw new ForbiddenException('You can only delete your own messages');
    }

    message.isDeleted = true;
    message.content = 'This message was deleted';
    message.mediaUrl = '';
    message.mediaMetadata = undefined;
    await message.save();

    return {
      id: message._id.toString(),
      isDeleted: true,
      message: 'Message deleted successfully',
    };
  }
}
