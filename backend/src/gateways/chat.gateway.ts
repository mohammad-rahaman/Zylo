import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Logger, UseGuards } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { RedisService } from '../redis/redis.service';
import { MessagesService } from '../messages/messages.service';
import { ConversationsService } from '../conversations/conversations.service';
import { User, UserDocument } from '../database/schemas/user.schema';
import { MessageStatus, MessageType } from '../database/schemas/message.schema';
import { NotificationsService } from '../notifications/notifications.service';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
  pingInterval: 10000,
  pingTimeout: 5000,
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(ChatGateway.name);

  constructor(
    private jwtService: JwtService,
    private configService: ConfigService,
    private redisService: RedisService,
    private messagesService: MessagesService,
    private conversationsService: ConversationsService,
    private notificationsService: NotificationsService,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const token =
        client.handshake.auth?.token ||
        client.handshake.headers?.authorization?.replace('Bearer ', '');

      if (!token) {
        this.logger.warn(`WS connection rejected: No token provided (${client.id})`);
        client.disconnect();
        return;
      }

      const payload = this.jwtService.verify(token, {
        secret: this.configService.get<string>('jwt.accessSecret'),
      });

      const userId = payload.sub;
      client.data.userId = userId;
      client.data.user = payload;

      // Join personal room for 1-to-1 event routing
      client.join(`user:${userId}`);

      // Set user online in Redis presence & MongoDB
      await this.redisService.setUserOnline(userId, client.id);
      await this.userModel.findByIdAndUpdate(userId, {
        $set: { isOnline: true, lastSeen: new Date() },
      });

      // Broadcast online status to contacts
      this.server.emit('presence:update', {
        userId,
        isOnline: true,
        lastSeen: new Date(),
      });

      this.logger.log(`User connected: ${payload.username} (${userId}) on socket ${client.id}`);
    } catch (err) {
      this.logger.warn(`WS connection error: ${err.message}`);
      client.disconnect();
    }
  }

  async handleDisconnect(client: Socket) {
    const userId = client.data?.userId;
    if (userId) {
      const { isCompletelyOffline, lastSeen } = await this.redisService.setUserOffline(
        userId,
        client.id,
      );

      if (isCompletelyOffline) {
        await this.userModel.findByIdAndUpdate(userId, {
          $set: { isOnline: false, lastSeen },
        });

        // Broadcast offline status
        this.server.emit('presence:update', {
          userId,
          isOnline: false,
          lastSeen,
        });
      }

      this.logger.log(`User disconnected: ${userId} socket ${client.id}`);
    }
  }

  // Join Conversation Room
  @SubscribeMessage('conversation:join')
  async handleJoinConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    const userId = client.data.userId;
    if (!userId || !data.conversationId) return;

    client.join(`conversation:${data.conversationId}`);
    // Reset unread count for user in this conversation
    await this.conversationsService.resetUnread(data.conversationId, userId);
  }

  // Leave Conversation Room
  @SubscribeMessage('conversation:leave')
  handleLeaveConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    if (data.conversationId) {
      client.leave(`conversation:${data.conversationId}`);
    }
  }

  // Send Realtime Message
  @SubscribeMessage('message:send')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: {
      conversationId: string;
      content?: string;
      type?: MessageType;
      mediaUrl?: string;
      mediaMetadata?: any;
      replyToId?: string;
      tempId?: string;
    },
  ) {
    const senderId = client.data.userId;
    if (!senderId) return;

    try {
      const message = await this.messagesService.sendMessage(
        data.conversationId,
        senderId,
        {
          type: data.type || MessageType.TEXT,
          content: data.content,
          mediaUrl: data.mediaUrl,
          mediaMetadata: data.mediaMetadata,
          replyToId: data.replyToId,
        },
      );

      const conv = await this.conversationsService.getConversationById(
        data.conversationId,
        senderId,
      );

      // Emit new message to conversation room and to participant user rooms
      const payload = {
        ...message,
        tempId: data.tempId,
      };

      this.server.to(`conversation:${data.conversationId}`).emit('message:new', payload);

      // Also deliver to individual participants
      if (conv?.participants) {
        for (const p of conv.participants) {
          const pId = (p as any)._id?.toString() || (p as any).id?.toString();
          this.server.to(`user:${pId}`).emit('conversation:updated', {
            conversationId: data.conversationId,
            lastMessage: message,
          });

          // If participant is not the sender, check if offline to send push notification
          if (pId !== senderId) {
            const presence = await this.redisService.getUserPresence(pId);
            if (!presence.isOnline) {
              const sender = await this.userModel.findById(senderId).lean();
              await this.notificationsService.sendPushToUser(
                pId,
                sender?.displayName || 'New Message',
                data.type === MessageType.TEXT
                  ? data.content || 'Sent a message'
                  : `Sent a ${data.type || 'file'}`,
                {
                  conversationId: data.conversationId,
                  messageId: message.id,
                },
              );
            }
          }
        }
      }

      return { status: 'ok', data: message };
    } catch (err) {
      this.logger.error(`Error sending message over WS: ${err.message}`);
      return { status: 'error', message: err.message };
    }
  }

  // Realtime Delivery Receipt
  @SubscribeMessage('message:delivered')
  async handleMessageDelivered(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { messageId: string; conversationId: string },
  ) {
    const userId = client.data.userId;
    if (!userId || !data.messageId) return;

    try {
      await this.messagesService.updateMessageStatus(data.messageId, userId, {
        status: MessageStatus.DELIVERED,
      });

      this.server.to(`conversation:${data.conversationId}`).emit('message:status_updated', {
        messageId: data.messageId,
        conversationId: data.conversationId,
        status: MessageStatus.DELIVERED,
        userId,
      });
    } catch (err: any) {
      this.logger.warn(`Failed to process message:delivered for ${data.messageId}: ${err.message}`);
    }
  }

  // Realtime Read Receipt
  @SubscribeMessage('message:read')
  async handleMessageRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { messageId: string; conversationId: string },
  ) {
    const userId = client.data.userId;
    if (!userId || !data.messageId) return;

    try {
      await this.messagesService.updateMessageStatus(data.messageId, userId, {
        status: MessageStatus.READ,
      });

      await this.conversationsService.resetUnread(data.conversationId, userId);

      this.server.to(`conversation:${data.conversationId}`).emit('message:status_updated', {
        messageId: data.messageId,
        conversationId: data.conversationId,
        status: MessageStatus.READ,
        userId,
        readAt: new Date(),
      });
    } catch (err: any) {
      this.logger.warn(`Failed to process message:read for ${data.messageId}: ${err.message}`);
    }
  }

  // Typing Start
  @SubscribeMessage('typing:start')
  async handleTypingStart(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    const userId = client.data.userId;
    if (!userId || !data.conversationId) return;

    try {
      await this.redisService.setTyping(data.conversationId, userId);

      // Broadcast typing indicator to others in conversation
      client.to(`conversation:${data.conversationId}`).emit('typing:started', {
        conversationId: data.conversationId,
        userId,
        username: client.data.user?.username,
      });
    } catch (err: any) {
      this.logger.warn(`Failed to process typing:start: ${err.message}`);
    }
  }

  // Typing Stop
  @SubscribeMessage('typing:stop')
  async handleTypingStop(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    const userId = client.data.userId;
    if (!userId || !data.conversationId) return;

    try {
      await this.redisService.clearTyping(data.conversationId, userId);

      client.to(`conversation:${data.conversationId}`).emit('typing:stopped', {
        conversationId: data.conversationId,
        userId,
      });
    } catch (err: any) {
      this.logger.warn(`Failed to process typing:stop: ${err.message}`);
    }
  }

  // Message Deletion Broadcast
  @SubscribeMessage('message:delete')
  async handleMessageDelete(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { messageId: string; conversationId: string },
  ) {
    const userId = client.data.userId;
    if (!userId || !data.messageId) return;

    try {
      await this.messagesService.deleteMessage(data.messageId, userId);

      this.server.to(`conversation:${data.conversationId}`).emit('message:deleted', {
        messageId: data.messageId,
        conversationId: data.conversationId,
      });
    } catch (err: any) {
      this.logger.warn(`Failed to process message:delete for ${data.messageId}: ${err.message}`);
    }
  }
}
