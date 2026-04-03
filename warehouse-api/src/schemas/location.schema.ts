import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type LocationDocument = Location & Document;

@Schema({ timestamps: true })
export class Location {
  @Prop({ required: true, unique: true, trim: true })
  code: string;

  @Prop({ trim: true })
  description: string;

  @Prop({ type: Date })
  checkedAt: Date;
}

export const LocationSchema = SchemaFactory.createForClass(Location);
