import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ImportLogDocument = ImportLog & Document;

@Schema({ timestamps: true })
export class ImportLog {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @Prop({ required: true })
  userName: string;

  @Prop({ required: true, enum: ['skus', 'locations', 'inventory'] })
  importType: string;

  @Prop({ required: true })
  filename: string;

  @Prop({ required: true })
  total: number;

  @Prop({ required: true })
  created: number;

  @Prop({ required: true })
  updated: number;

  @Prop({ required: true })
  skipped: number;

  @Prop({ type: [{ row: Number, message: String }], default: [] })
  importErrors: { row: number; message: string }[];
}

export const ImportLogSchema = SchemaFactory.createForClass(ImportLog);
