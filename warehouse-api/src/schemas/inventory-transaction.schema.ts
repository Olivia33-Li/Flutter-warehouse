import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type InventoryTransactionDocument = InventoryTransaction & Document;

@Schema({ timestamps: true })
export class InventoryTransaction {
  @Prop({ required: true })
  skuCode: string;

  @Prop({ type: Types.ObjectId, ref: 'Location', required: true })
  locationId: Types.ObjectId;

  @Prop({ required: true })
  locationCode: string;

  @Prop({ required: true, enum: ['IN', 'OUT', 'ADJUST'] })
  type: string;

  @Prop({ type: Number, required: true })
  quantity: number;

  @Prop({ type: Number })
  boxes: number;

  @Prop({ type: Number })
  unitsPerBox: number;

  @Prop()
  note: string;

  @Prop()
  businessAction: string;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  operatorId: Types.ObjectId;

  @Prop({ required: true })
  operatorName: string;
}

export const InventoryTransactionSchema = SchemaFactory.createForClass(InventoryTransaction);
InventoryTransactionSchema.index({ skuCode: 1, locationId: 1, createdAt: -1 });
InventoryTransactionSchema.index({ createdAt: -1 });
