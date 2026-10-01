import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type MomentDocument = Moment & Document;

export enum MomentStatus {
  ACTIVE = 'active',
  EXPIRING_SOON = 'expiring_soon',
  EXPIRED = 'expired',
}

@Schema({ timestamps: true })
export class Moment {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  participantA: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  participantB: Types.ObjectId;

  @Prop({ type: [{ type: Types.ObjectId, ref: 'User' }], required: true })
  participants: Types.ObjectId[];

  @Prop({ type: Number, default: 0 })
  currentCount: number;

  @Prop({ type: String, enum: Object.values(MomentStatus), default: MomentStatus.ACTIVE })
  status: MomentStatus;

  @Prop({ type: Date, default: null })
  participantAInteractedAt: Date | null;

  @Prop({ type: Date, default: null })
  participantBInteractedAt: Date | null;

  @Prop({ type: Date, default: () => new Date() })
  currentWindowStartedAt: Date;

  @Prop({ type: Date, default: null })
  lastCompletedAt: Date | null;

  @Prop({ type: Date, required: true })
  expiresAt: Date;

  @Prop({ type: Date, default: () => new Date() })
  startedAt: Date;
}

export const MomentSchema = SchemaFactory.createForClass(Moment);

// Compound index on normalized participant pair and status
MomentSchema.index({ participantA: 1, participantB: 1, status: 1 });
MomentSchema.index({ participants: 1 });
MomentSchema.index({ expiresAt: 1 });

/**
 * Normalizes two participant IDs in a deterministic order (alphabetical by string)
 * ensuring Rahul + Ananya and Ananya + Rahul always resolve to the exact same pair.
 */
export function normalizeParticipants(id1: string, id2: string) {
  const sorted = [id1, id2].sort();
  return {
    participantA: new Types.ObjectId(sorted[0]),
    participantB: new Types.ObjectId(sorted[1]),
    participants: [new Types.ObjectId(sorted[0]), new Types.ObjectId(sorted[1])],
  };
}
