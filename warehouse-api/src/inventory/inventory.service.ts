import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Inventory, InventoryDocument } from '../schemas/inventory.schema';
import { Sku, SkuDocument } from '../schemas/sku.schema';
import { Location, LocationDocument } from '../schemas/location.schema';
import { HistoryService } from '../history/history.service';
import { UpsertInventoryDto } from './dto/inventory.dto';

@Injectable()
export class InventoryService {
  constructor(
    @InjectModel(Inventory.name) private inventoryModel: Model<InventoryDocument>,
    @InjectModel(Sku.name) private skuModel: Model<SkuDocument>,
    @InjectModel(Location.name) private locationModel: Model<LocationDocument>,
    private historyService: HistoryService,
  ) {}

  async findAll(skuId?: string, locationId?: string) {
    const filter: any = {};
    if (skuId) filter.skuId = new Types.ObjectId(skuId);
    if (locationId) filter.locationId = new Types.ObjectId(locationId);

    return this.inventoryModel
      .find(filter)
      .populate('skuId', 'sku name barcode cartonQty')
      .populate('locationId', 'code description')
      .lean();
  }

  async upsert(dto: UpsertInventoryDto, user: any) {
    const [sku, location] = await Promise.all([
      this.skuModel.findById(dto.skuId),
      this.locationModel.findById(dto.locationId),
    ]);
    if (!sku) throw new NotFoundException('SKU 不存在');
    if (!location) throw new NotFoundException('位置不存在');

    const filter = {
      skuId: new Types.ObjectId(dto.skuId),
      locationId: new Types.ObjectId(dto.locationId),
    };

    const existing = await this.inventoryModel.findOne(filter);
    const isNew = !existing;

    const record = await this.inventoryModel.findOneAndUpdate(
      filter,
      { quantity: dto.quantity },
      { upsert: true, new: true },
    );

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: isNew ? 'add' : 'edit',
      entity: 'inventory',
      description: `${isNew ? '新增' : '更新'}库存: ${sku.sku} @ ${location.code} = ${dto.quantity} 箱`,
    });

    return record;
  }

  async remove(id: string, user: any) {
    const record = await this.inventoryModel
      .findById(id)
      .populate('skuId', 'sku')
      .populate('locationId', 'code');
    if (!record) throw new NotFoundException('库存记录不存在');

    const skuCode = (record.skuId as any).sku;
    const locationCode = (record.locationId as any).code;

    await this.inventoryModel.findByIdAndDelete(id);

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'delete',
      entity: 'inventory',
      description: `删除库存: ${skuCode} @ ${locationCode}`,
    });

    return { message: '库存记录已删除' };
  }

  async clearAll(user: any) {
    await this.inventoryModel.deleteMany({});
    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'delete',
      entity: 'inventory',
      description: '清空所有库存',
    });
    return { message: '库存已清空' };
  }
}
