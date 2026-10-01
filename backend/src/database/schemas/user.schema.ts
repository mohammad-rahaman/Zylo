import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type UserDocument = User & Document;

@Schema({ timestamps: true })
export class User {
  @Prop({ required: true, unique: true, trim: true, lowercase: true, index: true })
  username: string;

  @Prop({ required: true, trim: true })
  displayName: string;

  @Prop({ required: true, unique: true, trim: true, lowercase: true, index: true })
  email: string;

  @Prop({ required: true, select: false })
  passwordHash: string;

  @Prop({ default: '' })
  profilePhoto: string;

  @Prop({ default: 'Hey there! I am using Zylo.' })
  bio: string;

  @Prop({ default: false, index: true })
  isOnline: boolean;

  @Prop({ default: Date.now })
  lastSeen: Date;

  createdAt: Date;
  updatedAt: Date;
}

export const UserSchema = SchemaFactory.createForClass(User);

// Indexes
UserSchema.index({ username: 'text', displayName: 'text' });
