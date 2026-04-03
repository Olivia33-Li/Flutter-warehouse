import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type InventoryDocument = Inventory & Document;

@Schema({ timestamps: true })
export class Inventory {
  @Prop({ type: Types.ObjectId, ref: 'Sku', required: true })
  skuId: Types.ObjectId;

  @Prop({ required: true, trim: true })
  skuCode: string;

  @Prop({ type: Types.ObjectId, ref: 'Location', required: true })
  locationId: Types.ObjectId;

  @Prop({ type: Number, default: 0, min: 0 })
  boxes: number;

  @Prop({ type: Number, default: 1, min: 1 })
  unitsPerBox: number;

  @Prop({ type: [{ boxes: Number, unitsPerBox: Number, _id: false }], default: [] })
  configurations: { boxes: number; unitsPerBox: number }[];

  @Prop({ type: Number, default: 0, min: 0 })
  quantity: number;

  @Prop({ type: String, enum: ['confirmed', 'pending_count', 'temporary'], default: 'confirmed' })
  stockStatus: string;

  @Prop({ type: Boolean, default: false })
  quantityUnknown: boolean;

  @Prop({ type: Boolean, default: false })
  boxesOnlyMode: boolean;

  @Prop({ trim: true })
  note: string;
}

export const InventorySchema = SchemaFactory.createForClass(Inventory);
InventorySchema.index({ skuId: 1, locationId: 1 }, { unique: true });
InventorySchema.index({ skuCode: 1 });
