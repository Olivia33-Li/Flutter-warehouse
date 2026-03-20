import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type InventoryDocument = Inventory & Document;

@Schema({ timestamps: true })
export class Inventory {
  @Prop({ type: Types.ObjectId, ref: 'Sku', required: true })
  skuId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Location', required: true })
  locationId: Types.ObjectId;

  @Prop({ required: true, min: 0 })
  quantity: number;
}

export const InventorySchema = SchemaFactory.createForClass(Inventory);

InventorySchema.index({ skuId: 1, locationId: 1 }, { unique: true });
