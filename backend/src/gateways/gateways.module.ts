import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule } from '../database/database.module';
import { RedisModule } from '../redis/redis.module';
import { MessagesModule } from '../messages/messages.module';
import { ConversationsModule } from '../conversations/conversations.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { ChatGateway } from './chat.gateway';

@Module({
  imports: [
    DatabaseModule,
    RedisModule,
    MessagesModule,
    ConversationsModule,
    NotificationsModule,
    JwtModule,
    ConfigModule,
  ],
  providers: [ChatGateway],
  exports: [ChatGateway],
})
export class GatewaysModule {}
