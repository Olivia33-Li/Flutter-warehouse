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

  @Prop({ type: Number, default: 0, min: 0 })
  unitsPerBox: number;

  @Prop({ type: [{ boxes: Number, unitsPerBox: Number, _id: false }], default: [] })
  configurations: { boxes: number; unitsPerBox: number }[];

  /** Pieces not belonging to any carton spec (by-qty stockIn). */
  @Prop({ type: Number, default: 0, min: 0 })
  loosePcs: number;

  /** Cartons with no known pcs/carton (boxes-only stockIn). Do NOT count toward quantity. */
  @Prop({ type: Number, default: 0, min: 0 })
  unconfiguredCartons: number;

  @Prop({ type: Number, default: 0, min: 0 })
  quantity: number;

  @Prop({ type: String, enum: ['confirmed', 'pending_count', 'temporary', 'completed_split', 'completed_merge'], default: 'confirmed' })
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
