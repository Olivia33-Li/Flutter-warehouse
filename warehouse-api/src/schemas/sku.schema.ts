import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type SkuDocument = Sku & Document;

export type SkuStatus = 'active' | 'archived';

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

  // 'active' (default) | 'archived' — null/undefined treated as 'active' for backwards compat
  @Prop({ type: String, enum: ['active', 'archived'], default: 'active' })
  status: SkuStatus;

  @Prop({
    type: [{ barcode: String, changedBy: String, source: String, changedAt: Date, _id: false }],
    default: [],
  })
  barcodeHistory: { barcode: string; changedBy: string; source: string; changedAt: Date }[];
}

export const SkuSchema = SchemaFactory.createForClass(Sku);

SkuSchema.index({ sku: 'text', name: 'text', barcode: 'text' });
SkuSchema.index({ status: 1 });
