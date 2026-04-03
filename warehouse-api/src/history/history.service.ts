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
}

@Injectable()
export class HistoryService {
  constructor(
    @InjectModel(ChangeRecord.name) private changeModel: Model<ChangeRecordDocument>,
  ) {}

  async log(params: LogParams) {
    return this.changeModel.create({
      ...params,
      userId: new Types.ObjectId(params.userId),
    });
  }

  async findAll(query: {
    userId?: string;
    action?: string;
    entity?: string;
    keyword?: string;
    businessAction?: string;
    locationCode?: string;
    startDate?: string;
    endDate?: string;
    userName?: string;
    inventoryChangingOnly?: boolean;
    page?: number;
    limit?: number;
  }) {
    const {
      userId, action, entity, keyword, businessAction,
      locationCode, startDate, endDate, userName,
      inventoryChangingOnly, page = 1, limit = 50,
    } = query;

    const filter: any = {};

    if (userId) filter.userId = new Types.ObjectId(userId);
    if (action) filter.action = action;
    if (entity) filter.entity = entity;
    if (businessAction) filter.businessAction = businessAction;
    if (userName) filter.userName = { $regex: userName, $options: 'i' };
    if (inventoryChangingOnly) filter.entity = 'inventory';

    const andConditions: any[] = [];
    if (keyword) andConditions.push({ description: { $regex: keyword, $options: 'i' } });
    if (locationCode) andConditions.push({ description: { $regex: locationCode, $options: 'i' } });
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
