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

  @Prop({ type: String, enum: ['add', 'edit', 'delete', 'import'], required: true })
  action: ActionType;

  @Prop({ type: String, enum: ['sku', 'location', 'inventory', 'user'], required: true })
  entity: EntityType;

  @Prop({ required: true })
  description: string;
}

export const ChangeRecordSchema = SchemaFactory.createForClass(ChangeRecord);
