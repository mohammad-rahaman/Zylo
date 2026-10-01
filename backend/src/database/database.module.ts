import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { User, UserSchema } from './schemas/user.schema';
import { Conversation, ConversationSchema } from './schemas/conversation.schema';
import { Message, MessageSchema } from './schemas/message.schema';
import { RefreshToken, RefreshTokenSchema } from './schemas/refresh-token.schema';
import { DeviceToken, DeviceTokenSchema } from './schemas/device-token.schema';
import { BlockedUser, BlockedUserSchema } from './schemas/blocked-user.schema';
import { MomentShortcut, MomentShortcutSchema } from './schemas/moment-shortcut.schema';

@Module({
  imports: [
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        uri: configService.get<string>('database.uri'),
      }),
    }),
    MongooseModule.forFeature([
      { name: User.name, schema: UserSchema },
      { name: Conversation.name, schema: ConversationSchema },
      { name: Message.name, schema: MessageSchema },
      { name: RefreshToken.name, schema: RefreshTokenSchema },
      { name: DeviceToken.name, schema: DeviceTokenSchema },
      { name: BlockedUser.name, schema: BlockedUserSchema },
      { name: MomentShortcut.name, schema: MomentShortcutSchema },
    ]),
  ],
  exports: [MongooseModule],
})
export class DatabaseModule {}
