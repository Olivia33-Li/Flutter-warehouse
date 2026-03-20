import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { ChangeRecord, ChangeRecordDocument, ActionType, EntityType } from '../schemas/change-record.schema';

export interface LogParams {
  userId: string;
  userName: string;
  action: ActionType;
  entity: EntityType;
  description: string;
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
    page?: number;
    limit?: number;
  }) {
    const { userId, action, entity, keyword, page = 1, limit = 50 } = query;
    const filter: any = {};

    if (userId) filter.userId = new Types.ObjectId(userId);
    if (action) filter.action = action;
    if (entity) filter.entity = entity;
    if (keyword) filter.description = { $regex: keyword, $options: 'i' };

    const [records, total] = await Promise.all([
      this.changeModel
        .find(filter)
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .lean(),
      this.changeModel.countDocuments(filter),
    ]);

    return { records, total, page, limit };
  }
}
