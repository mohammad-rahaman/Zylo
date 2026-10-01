import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Moment, MomentSchema } from '../database/schemas/moment.schema';
import { User, UserSchema } from '../database/schemas/user.schema';
import {
  MomentShortcut,
  MomentShortcutSchema,
} from '../database/schemas/moment-shortcut.schema';
import { ConversationsModule } from '../conversations/conversations.module';
import { MessagesModule } from '../messages/messages.module';
import { UsersModule } from '../users/users.module';
import { MomentsService } from './moments.service';
import { MomentsController } from './moments.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Moment.name, schema: MomentSchema },
      { name: User.name, schema: UserSchema },
      { name: MomentShortcut.name, schema: MomentShortcutSchema },
    ]),
    ConversationsModule,
    forwardRef(() => MessagesModule),
    UsersModule,
  ],
  controllers: [MomentsController],
  providers: [MomentsService],
  exports: [MomentsService],
})
export class MomentsModule {}
