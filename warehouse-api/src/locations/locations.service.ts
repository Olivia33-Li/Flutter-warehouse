import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Location, LocationDocument } from '../schemas/location.schema';
import { Inventory, InventoryDocument } from '../schemas/inventory.schema';
import { HistoryService } from '../history/history.service';
import { CreateLocationDto, UpdateLocationDto } from './dto/location.dto';

@Injectable()
export class LocationsService {
  constructor(
    @InjectModel(Location.name) private locationModel: Model<LocationDocument>,
    @InjectModel(Inventory.name) private inventoryModel: Model<InventoryDocument>,
    private historyService: HistoryService,
  ) {}

  async findAll(search?: string) {
    const filter: any = {};
    if (search) {
      filter.$or = [
        { code: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
      ];
    }
    return this.locationModel.find(filter).lean();
  }

  async findOne(id: string) {
    const location = await this.locationModel.findById(id).lean();
    if (!location) throw new NotFoundException('位置不存在');

    const inventory = await this.inventoryModel
      .find({ locationId: new Types.ObjectId(id) })
      .populate('skuId', 'sku name barcode cartonQty')
      .lean();

    const formatted = inventory.map((r) => {
      const sku = r.skuId as any;
      const skuCode = r.skuCode || sku?.sku || '';
      const isBoxesOnly = !!(r as any).boxesOnlyMode;
      const boxes = (r.boxes ?? 0) > 0 ? r.boxes : (r.quantity ?? 0);
      const unitsPerBox = r.unitsPerBox ?? 1;
      return {
        ...r,
        skuCode,
        skuId: sku?._id?.toString() ?? r.skuId?.toString(),
        skuName: sku?.name,
        boxes,
        unitsPerBox,
        quantity: isBoxesOnly ? 0 : (r.quantity ?? boxes * unitsPerBox),
      };
    });

    const totalQty = formatted.reduce((sum, r) => (r as any).boxesOnlyMode ? sum : sum + (r.quantity ?? 0), 0);
    const totalBoxes = formatted.reduce((sum, r) => sum + (r.boxes ?? 0), 0);
    const skuCount = formatted.length;

    return { ...location, inventory: formatted, totalQty, totalBoxes, skuCount };
  }

  async create(dto: CreateLocationDto, user: any) {
    const exists = await this.locationModel.findOne({ code: dto.code.toUpperCase() });
    if (exists) throw new ConflictException('位置代码已存在');

    const location = await this.locationModel.create({ ...dto, code: dto.code.toUpperCase() });

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'add',
      entity: 'location',
      businessAction: '新建库位',
      description: `新增位置: ${location.code}`,
    });

    return location;
  }

  async update(id: string, dto: UpdateLocationDto, user: any) {
    const location = await this.locationModel.findByIdAndUpdate(id, dto, { new: true });
    if (!location) throw new NotFoundException('位置不存在');

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'location',
      businessAction: '编辑库位',
      description: `编辑位置: ${location.code}`,
    });

    return location;
  }

  async check(id: string, checked: boolean, user: any) {
    const location = await this.locationModel.findByIdAndUpdate(
      id,
      { checkedAt: checked ? new Date() : null },
      { new: true },
    );
    if (!location) throw new NotFoundException('位置不存在');

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'location',
      businessAction: checked ? '标记已检查' : '取消已检查',
      description: `${checked ? '标记' : '取消'}库位已检查: ${location.code}`,
    });

    return location;
  }

  async transfer(sourceId: string, dto: {
    targetLocationId: string;
    skuCodes?: string[];
    conflictResolution?: string;
  }, user: any) {
    return this._moveInventory(sourceId, dto, user, true);
  }

  async copy(sourceId: string, dto: {
    targetLocationId: string;
    skuCodes?: string[];
    conflictResolution?: string;
  }, user: any) {
    return this._moveInventory(sourceId, dto, user, false);
  }

  private async _moveInventory(
    sourceId: string,
    dto: { targetLocationId: string; skuCodes?: string[]; conflictResolution?: string },
    user: any,
    deleteSource: boolean,
  ) {
    const source = await this.locationModel.findById(sourceId);
    if (!source) throw new NotFoundException('源库位不存在');

    const target = await this.locationModel.findById(dto.targetLocationId);
    if (!target) throw new NotFoundException('目标库位不存在');

    const filter: any = { locationId: new Types.ObjectId(sourceId) };
    if (dto.skuCodes && dto.skuCodes.length > 0) {
      filter.skuCode = { $in: dto.skuCodes };
    }

    const sourceInv = await this.inventoryModel.find(filter).lean();
    let moved = 0, skipped = 0;
    const conflictResolution = dto.conflictResolution ?? 'skip';

    for (const inv of sourceInv) {
      const existing = await this.inventoryModel.findOne({
        skuId: inv.skuId,
        locationId: new Types.ObjectId(dto.targetLocationId),
      });

      if (existing) {
        if (conflictResolution === 'overwrite') {
          existing.boxes = inv.boxes;
          existing.unitsPerBox = inv.unitsPerBox;
          existing.configurations = inv.configurations;
          existing.quantity = inv.quantity;
          existing.stockStatus = inv.stockStatus;
          await existing.save();
          moved++;
        } else if (conflictResolution === 'merge') {
          existing.boxes = (existing.boxes ?? 0) + (inv.boxes ?? 0);
          existing.quantity = (existing.quantity ?? 0) + (inv.quantity ?? 0);
          await existing.save();
          moved++;
        } else {
          skipped++;
          continue;
        }
      } else {
        await this.inventoryModel.create({
          ...inv,
          _id: undefined,
          locationId: new Types.ObjectId(dto.targetLocationId),
        });
        moved++;
      }

      if (deleteSource) {
        await this.inventoryModel.findByIdAndDelete(inv._id);
      }
    }

    const action = deleteSource ? '批量转移' : '批量复制';
    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'location',
      businessAction: action,
      description: `${action}: ${source.code} → ${target.code}，${moved} 条成功，${skipped} 条跳过`,
    });

    return { moved, skipped };
  }

  async remove(id: string, user: any) {
    const location = await this.locationModel.findById(id);
    if (!location) throw new NotFoundException('位置不存在');

    await this.inventoryModel.deleteMany({ locationId: new Types.ObjectId(id) });
    await this.locationModel.findByIdAndDelete(id);

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'delete',
      entity: 'location',
      businessAction: '删除库位',
      description: `删除位置: ${location.code}`,
    });

    return { message: '位置已删除' };
  }
}
