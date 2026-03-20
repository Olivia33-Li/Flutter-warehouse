import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type SkuDocument = Sku & Document;

@Schema({ timestamps: true })
export class Sku {
  @Prop({ required: true, unique: true, trim: true })
  sku: string;

  @Prop({ trim: true })
  name: string;

  @Prop({ trim: true })
  barcode: string;

  @Prop({ type: Number, min: 1 })
  cartonQty: number;
}

export const SkuSchema = SchemaFactory.createForClass(Sku);

SkuSchema.index({ sku: 'text', name: 'text', barcode: 'text' });
