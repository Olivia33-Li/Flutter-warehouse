import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type UserDocument = User & Document;

// New 3-tier role system. Legacy values 'editor' / 'viewer' are handled at runtime
// via normalizeRole() in permissions.ts and are never written to the DB going forward.
export type UserRole = 'admin' | 'supervisor' | 'staff';

@Schema({ timestamps: true })
export class User {
  @Prop({ required: true, unique: true, trim: true })
  username: string;

  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  passwordHash: string;

  @Prop({
    type: String,
    // Accept both old and new role names so existing data keeps loading
    enum: ['admin', 'supervisor', 'staff', 'editor', 'viewer'],
    default: 'staff',
  })
  role: UserRole;

  /** false = account is disabled; login is rejected immediately */
  @Prop({ type: Boolean, default: true })
  isActive: boolean;

  @Prop({ type: Date })
  lastLoginAt: Date;
}

export const UserSchema = SchemaFactory.createForClass(User);
