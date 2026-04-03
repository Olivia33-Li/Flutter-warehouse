import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Inventory, InventoryDocument } from '../schemas/inventory.schema';
import { Sku, SkuDocument } from '../schemas/sku.schema';
import { Location, LocationDocument } from '../schemas/location.schema';
import { ImportLog, ImportLogDocument } from '../schemas/import-log.schema';
import { HistoryService } from '../history/history.service';

@Injectable()
export class InventoryService {
  constructor(
    @InjectModel(Inventory.name) private inventoryModel: Model<InventoryDocument>,
    @InjectModel(Sku.name) private skuModel: Model<SkuDocument>,
    @InjectModel(Location.name) private locationModel: Model<LocationDocument>,
    @InjectModel(ImportLog.name) private importLogModel: Model<ImportLogDocument>,
    private historyService: HistoryService,
  ) {}

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  private computeQuantity(inv: Partial<Inventory>): number {
    if (inv.quantityUnknown || inv.boxesOnlyMode) return 0;
    if (inv.configurations && inv.configurations.length > 0) {
      return inv.configurations.reduce((s, c) => s + c.boxes * c.unitsPerBox, 0);
    }
    return (inv.boxes ?? 0) * (inv.unitsPerBox ?? 1);
  }

  private formatRecord(r: any) {
    const sku = r.skuId as any;
    const skuCode = r.skuCode || sku?.sku || '';
    const boxes = (r.boxes ?? 0) > 0 ? r.boxes : (r.quantity ?? 0);
    const unitsPerBox = r.unitsPerBox ?? 1;
    return {
      ...r,
      skuCode,
      skuId: sku?._id?.toString() ?? r.skuId?.toString(),
      skuName: sku?.name,
      boxes,
      unitsPerBox,
      quantity: r.quantity ?? boxes * unitsPerBox,
    };
  }

  // ─── CRUD ─────────────────────────────────────────────────────────────────────

  async findAll(params: {
    skuCode?: string;
    locationId?: string;
    pendingOnly?: boolean;
    stockStatus?: string;
  }) {
    const filter: any = {};
    if (params.skuCode) filter.skuCode = { $regex: params.skuCode, $options: 'i' };
    if (params.locationId) filter.locationId = new Types.ObjectId(params.locationId);
    if (params.pendingOnly) filter.stockStatus = 'pending_count';
    else if (params.stockStatus) filter.stockStatus = params.stockStatus;

    const records = await this.inventoryModel
      .find(filter)
      .populate('skuId', 'name sku barcode cartonQty')
      .populate('locationId', 'code description')
      .lean();

    return records.map((r) => this.formatRecord(r));
  }

  async create(dto: {
    skuCode: string;
    locationId: string;
    boxes?: number;
    unitsPerBox?: number;
    pendingCount?: boolean;
    boxesOnlyMode?: boolean;
    note?: string;
  }, user: any) {
    const sku = await this.skuModel.findOne({ sku: dto.skuCode.toUpperCase() });
    if (!sku) throw new NotFoundException(`SKU ${dto.skuCode} 不存在`);

    const location = await this.locationModel.findById(dto.locationId);
    if (!location) throw new NotFoundException('库位不存在');

    const existing = await this.inventoryModel.findOne({
      skuId: sku._id,
      locationId: new Types.ObjectId(dto.locationId),
    });
    if (existing) throw new BadRequestException(`${dto.skuCode} 在此库位已有库存记录`);

    const quantityUnknown = !dto.pendingCount && !dto.boxesOnlyMode && (dto.boxes ?? 0) === 0 && !dto.unitsPerBox;
    const stockStatus = dto.pendingCount ? 'pending_count' : 'confirmed';
    const partial = {
      boxes: dto.boxes ?? 0,
      unitsPerBox: dto.unitsPerBox ?? 1,
      quantityUnknown,
      boxesOnlyMode: dto.boxesOnlyMode ?? false,
    };

    const record = await this.inventoryModel.create({
      skuId: sku._id,
      skuCode: sku.sku,
      locationId: new Types.ObjectId(dto.locationId),
      ...partial,
      quantity: this.computeQuantity(partial),
      stockStatus,
      note: dto.note,
    });

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'add',
      entity: 'inventory',
      businessAction: '录入',
      description: `录入库存: ${sku.sku} @ ${location.code}`,
    });

    const populated = await this.inventoryModel
      .findById(record._id)
      .populate('skuId', 'name sku barcode cartonQty')
      .populate('locationId', 'code description')
      .lean();
    return this.formatRecord(populated);
  }

  async update(id: string, dto: {
    boxes?: number;
    unitsPerBox?: number;
    pendingCount?: boolean;
    boxesOnlyMode?: boolean;
  }, user: any) {
    const record = await this.inventoryModel
      .findById(id)
      .populate('skuId', 'sku')
      .populate('locationId', 'code');
    if (!record) throw new NotFoundException('库存记录不存在');

    if (dto.boxes !== undefined) record.boxes = dto.boxes;
    if (dto.unitsPerBox !== undefined) record.unitsPerBox = dto.unitsPerBox;
    if (dto.pendingCount !== undefined) {
      record.stockStatus = dto.pendingCount ? 'pending_count' : 'confirmed';
      record.quantityUnknown = false;
    }
    if (dto.boxesOnlyMode !== undefined) record.boxesOnlyMode = dto.boxesOnlyMode;
    record.quantity = this.computeQuantity(record);
    await record.save();

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'inventory',
      businessAction: '结构修改',
      description: `修改库存: ${(record.skuId as any).sku} @ ${(record.locationId as any).code}`,
    });

    const populated = await this.inventoryModel
      .findById(id)
      .populate('skuId', 'name sku barcode cartonQty')
      .populate('locationId', 'code description')
      .lean();
    return this.formatRecord(populated);
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
      businessAction: '删除库存',
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

  async clearAllData(user: any) {
    await this.inventoryModel.deleteMany({});
    await this.skuModel.deleteMany({});
    await this.locationModel.deleteMany({});
    await this.importLogModel.deleteMany({});
    return { message: '所有业务数据已清空' };
  }

  // ─── Transactions ─────────────────────────────────────────────────────────────

  async stockIn(dto: {
    skuCode: string;
    locationId: string;
    boxes: number;
    unitsPerBox?: number;
    note?: string;
    boxesOnlyMode?: boolean;
  }, user: any) {
    const sku = await this.skuModel.findOne({ sku: dto.skuCode.toUpperCase() });
    if (!sku) throw new NotFoundException(`SKU ${dto.skuCode} 不存在`);

    const location = await this.locationModel.findById(dto.locationId);
    if (!location) throw new NotFoundException('库位不存在');

    const existing = await this.inventoryModel.findOne({
      skuId: sku._id,
      locationId: new Types.ObjectId(dto.locationId),
    });

    if (existing) {
      existing.boxes = (existing.boxes ?? 0) + dto.boxes;
      if (dto.unitsPerBox) existing.unitsPerBox = dto.unitsPerBox;
      if (dto.boxesOnlyMode !== undefined) existing.boxesOnlyMode = dto.boxesOnlyMode;
      existing.stockStatus = 'confirmed';
      existing.quantityUnknown = false;
      existing.quantity = this.computeQuantity(existing);
      await existing.save();
    } else {
      const partial = {
        boxes: dto.boxes,
        unitsPerBox: dto.unitsPerBox ?? 1,
        quantityUnknown: false,
        boxesOnlyMode: dto.boxesOnlyMode ?? false,
      };
      await this.inventoryModel.create({
        skuId: sku._id,
        skuCode: sku.sku,
        locationId: new Types.ObjectId(dto.locationId),
        ...partial,
        quantity: this.computeQuantity(partial),
        stockStatus: 'confirmed',
        note: dto.note,
      });
    }

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'inventory',
      businessAction: '入库',
      description: `入库: ${sku.sku} @ ${location.code} +${dto.boxes}箱`,
    });

    return { message: '入库成功' };
  }

  async stockOut(dto: {
    skuCode: string;
    locationId: string;
    quantity: number;
    note?: string;
  }, user: any) {
    const sku = await this.skuModel.findOne({ sku: dto.skuCode.toUpperCase() });
    if (!sku) throw new NotFoundException(`SKU ${dto.skuCode} 不存在`);

    const location = await this.locationModel.findById(dto.locationId);
    if (!location) throw new NotFoundException('库位不存在');

    const record = await this.inventoryModel.findOne({
      skuId: sku._id,
      locationId: new Types.ObjectId(dto.locationId),
    });
    if (!record) throw new NotFoundException('库存记录不存在');

    const newQty = Math.max(0, record.quantity - dto.quantity);
    const newBoxes = record.unitsPerBox > 0 ? Math.floor(newQty / record.unitsPerBox) : 0;
    record.boxes = newBoxes;
    record.quantity = newQty;
    await record.save();

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'inventory',
      businessAction: '出库',
      description: `出库: ${sku.sku} @ ${location.code} -${dto.quantity}件`,
    });

    return { message: '出库成功' };
  }

  async stockAdjust(dto: {
    skuCode: string;
    locationId: string;
    quantity?: number;
    configurations?: { boxes: number; unitsPerBox: number }[];
    note?: string;
  }, user: any) {
    const sku = await this.skuModel.findOne({ sku: dto.skuCode.toUpperCase() });
    if (!sku) throw new NotFoundException(`SKU ${dto.skuCode} 不存在`);

    const location = await this.locationModel.findById(dto.locationId);
    if (!location) throw new NotFoundException('库位不存在');

    const record = await this.inventoryModel.findOne({
      skuId: sku._id,
      locationId: new Types.ObjectId(dto.locationId),
    });
    if (!record) throw new NotFoundException('库存记录不存在');

    if (dto.configurations && dto.configurations.length > 0) {
      record.configurations = dto.configurations;
      record.boxes = dto.configurations.reduce((s, c) => s + c.boxes, 0);
      record.quantity = this.computeQuantity({ configurations: dto.configurations });
    } else if (dto.quantity !== undefined) {
      record.quantity = dto.quantity;
      record.boxes = record.unitsPerBox > 0 ? Math.floor(dto.quantity / record.unitsPerBox) : 0;
    }
    record.stockStatus = 'confirmed';
    record.quantityUnknown = false;
    if (dto.note) record.note = dto.note;
    await record.save();

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'inventory',
      businessAction: '调整',
      description: `调整库存: ${sku.sku} @ ${location.code} = ${record.quantity}件`,
    });

    return { message: '调整成功' };
  }

  // ─── Legacy upsert (kept for import compatibility) ────────────────────────────

  async upsert(dto: { skuId: string; locationId: string; quantity: number }, user: any) {
    const sku = await this.skuModel.findById(dto.skuId);
    const location = await this.locationModel.findById(dto.locationId);
    if (!sku) throw new NotFoundException('SKU 不存在');
    if (!location) throw new NotFoundException('位置不存在');

    const filter = {
      skuId: new Types.ObjectId(dto.skuId),
      locationId: new Types.ObjectId(dto.locationId),
    };

    const existing = await this.inventoryModel.findOne(filter);
    const isNew = !existing;
    const boxes = sku.cartonQty ? Math.floor(dto.quantity / sku.cartonQty) : dto.quantity;
    const unitsPerBox = sku.cartonQty ?? 1;

    const record = await this.inventoryModel.findOneAndUpdate(
      filter,
      {
        skuCode: sku.sku,
        boxes,
        unitsPerBox,
        quantity: dto.quantity,
        stockStatus: 'confirmed',
        quantityUnknown: false,
        boxesOnlyMode: false,
      },
      { upsert: true, new: true },
    );

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: isNew ? 'add' : 'edit',
      entity: 'inventory',
      description: `${isNew ? '新增' : '更新'}库存: ${sku.sku} @ ${location.code}`,
    });

    return record;
  }
}
