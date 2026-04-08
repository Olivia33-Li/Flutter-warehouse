import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type PasswordResetRequestDocument = PasswordResetRequest & Document;

@Schema({ timestamps: true })
export class PasswordResetRequest {
  @Prop({ required: true, trim: true })
  username: string;

  @Prop({ required: true })
  displayName: string;

  @Prop({
    type: String,
    enum: ['pending', 'completed', 'rejected'],
    default: 'pending',
  })
  status: string;

  @Prop({ trim: true, default: '' })
  adminNote: string;

  @Prop({ trim: true, default: '' })
  userNote: string;

  @Prop({ type: Date, default: null })
  resolvedAt: Date | null;

  @Prop({ trim: true, default: '' })
  resolvedBy: string;
}

export const PasswordResetRequestSchema = SchemaFactory.createForClass(PasswordResetRequest);
PasswordResetRequestSchema.index({ username: 1 });
PasswordResetRequestSchema.index({ status: 1 });
