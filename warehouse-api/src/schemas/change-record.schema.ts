import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ChangeRecordDocument = ChangeRecord & Document;
export type ActionType = 'add' | 'edit' | 'delete' | 'import';
export type EntityType = 'sku' | 'location' | 'inventory' | 'user';

@Schema({ timestamps: true })
export class ChangeRecord {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @Prop({ required: true })
  userName: string;

  @Prop({ required: true })
  action: string;

  @Prop({ required: true })
  entity: string;

  @Prop()
  entityId: string;

  @Prop({ required: true })
  description: string;

  @Prop()
  businessAction: string;

  @Prop({ type: Object })
  details: Record<string, any>;

  @Prop({ type: Object })
  changes: Record<string, any>;

  // Strict per-location tag for copy/transfer records; allows exact filtering
  // without relying on description regex. Optional — old records lack this field.
  @Prop({ type: String })
  locationCode: string;
}

export const ChangeRecordSchema = SchemaFactory.createForClass(ChangeRecord);
ChangeRecordSchema.index({ createdAt: -1 });
ChangeRecordSchema.index({ entity: 1 });
ChangeRecordSchema.index({ businessAction: 1 });
ChangeRecordSchema.index({ locationCode: 1 });
