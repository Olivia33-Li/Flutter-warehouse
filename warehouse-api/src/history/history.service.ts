import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { ChangeRecord, ChangeRecordDocument } from '../schemas/change-record.schema';

export interface LogParams {
  userId: string;
  userName: string;
  action: string;
  entity: string;
  entityId?: string;
  description: string;
  businessAction?: string;
  details?: Record<string, any>;
  changes?: Record<string, any>;
  /** Strict per-location tag used by copy/transfer records for exact filtering. */
  locationCode?: string;
}

@Injectable()
export class HistoryService {
  constructor(
    @InjectModel(ChangeRecord.name) private changeModel: Model<ChangeRecordDocument>,
  ) {}

  async clearAll(): Promise<number> {
    const result = await this.changeModel.deleteMany({});
    return result.deletedCount ?? 0;
  }

  async log(params: LogParams) {
    return this.changeModel.create({
      ...params,
      userId: new Types.ObjectId(params.userId),
    });
  }

  private escapeRegex(s: string): string {
    return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  async findAll(query: {
    userId?: string;
    action?: string;
    entity?: string;
    keyword?: string;
    businessAction?: string;
    businessActions?: string[];
    locationCode?: string;
    skuCode?: string;
    startDate?: string;
    endDate?: string;
    userName?: string;
    inventoryChangingOnly?: boolean;
    page?: number;
    limit?: number;
  }) {
    const {
      userId, action, entity, keyword, businessAction, businessActions,
      locationCode, skuCode, startDate, endDate, userName,
      inventoryChangingOnly, page = 1, limit = 50,
    } = query;

    const filter: any = {};

    if (userId) filter.userId = new Types.ObjectId(userId);
    if (action) filter.action = action;
    if (entity) filter.entity = entity;
    if (inventoryChangingOnly) filter.entity = 'inventory';

    // businessAction: prefer array OR-match, fall back to single value
    if (businessActions && businessActions.length > 0) {
      filter.businessAction = { $in: businessActions };
    } else if (businessAction) {
      filter.businessAction = businessAction;
    }

    if (userName) filter.userName = { $regex: userName, $options: 'i' };

    const andConditions: any[] = [];
    if (keyword) andConditions.push({ description: { $regex: this.escapeRegex(keyword), $options: 'i' } });

    // SKU + location combined description match (e.g. "ASH008-SY2 @ B2C")
    if (skuCode && locationCode) {
      andConditions.push({
        description: {
          $regex: `${this.escapeRegex(skuCode)} @ ${this.escapeRegex(locationCode)}`,
          $options: 'i',
        },
      });
    } else if (skuCode) {
      andConditions.push({ description: { $regex: this.escapeRegex(skuCode), $options: 'i' } });
    } else if (locationCode) {
      // Prefer strict locationCode field (set on copy/transfer records for exact per-location
      // filtering). Fall back to description regex for old records that lack the field.
      andConditions.push({
        $or: [
          { locationCode: locationCode },
          { locationCode: { $exists: false }, description: { $regex: this.escapeRegex(locationCode), $options: 'i' } },
        ],
      });
    }

    if (andConditions.length > 0) filter.$and = andConditions;

    if (startDate || endDate) {
      filter.createdAt = {};
      if (startDate) filter.createdAt.$gte = new Date(startDate);
      if (endDate) {
        const end = new Date(endDate);
        end.setHours(23, 59, 59, 999);
        filter.createdAt.$lte = end;
      }
    }

    const [records, total] = await Promise.all([
      this.changeModel.find(filter).sort({ createdAt: -1 }).skip((page - 1) * limit).limit(limit).lean(),
      this.changeModel.countDocuments(filter),
    ]);

    return { records, total, page, limit };
  }
}
