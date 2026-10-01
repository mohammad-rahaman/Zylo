import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type MomentShortcutDocument = MomentShortcut & Document;

@Schema({ timestamps: true })
export class MomentShortcut {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true, index: true })
  ownerId: Types.ObjectId;

  @Prop({ required: true, trim: true })
  name: string;

  @Prop({ default: '✨' })
  emoji: string;

  @Prop({ type: [{ type: Types.ObjectId, ref: 'User' }], default: [] })
  contactIds: Types.ObjectId[];

  createdAt: Date;
  updatedAt: Date;
}

export const MomentShortcutSchema = SchemaFactory.createForClass(MomentShortcut);

// Compound index for user's shortcuts
MomentShortcutSchema.index({ ownerId: 1, name: 1 });
