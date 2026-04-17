import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Inventory, InventoryDocument } from '../schemas/inventory.schema';
import { Sku, SkuDocument } from '../schemas/sku.schema';
import { Location, LocationDocument } from '../schemas/location.schema';
import { ImportLog, ImportLogDocument } from '../schemas/import-log.schema';
import { InventoryTransaction, InventoryTransactionDocument } from '../schemas/inventory-transaction.schema';
import { HistoryService } from '../history/history.service';

@Injectable()
export class InventoryService {
  constructor(
    @InjectModel(Inventory.name) private inventoryModel: Model<InventoryDocument>,
    @InjectModel(Sku.name) private skuModel: Model<SkuDocument>,
    @InjectModel(Location.name) private locationModel: Model<LocationDocument>,
    @InjectModel(ImportLog.name) private importLogModel: Model<ImportLogDocument>,
    @InjectModel(InventoryTransaction.name) private txModel: Model<InventoryTransactionDocument>,
    private historyService: HistoryService,
  ) {}

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /**
   * Expand a record into a normalised configs array.
   * Returns null if the record cannot be converted to piece-count
   * (boxesOnlyMode or quantityUnknown).
   */
  private effectiveConfigs(r: any): { boxes: number; unitsPerBox: number }[] | null {
    if (r.quantityUnknown || r.boxesOnlyMode) return null;
    if (r.configurations && r.configurations.length > 0) {
      return r.configurations.map((c: any) => ({ boxes: c.boxes, unitsPerBox: c.unitsPerBox }));
    }
    const boxes = r.boxes ?? 0;
    const upb   = (r.unitsPerBox > 0 ? r.unitsPerBox : 1);
    if (boxes > 0) return [{ boxes, unitsPerBox: upb }];
    if (r.quantity > 0) return [{ boxes: r.quantity, unitsPerBox: 1 }];
    return []; // zero-stock but valid
  }

  /** Human-readable qty structure for history logs. */
  private describeQty(r: any): string {
    if (r.quantityUnknown) return '待清点';
    if (r.boxesOnlyMode)   return `${r.boxes}箱（无箱规）`;
    if (r.configurations && r.configurations.length > 0) {
      const parts = r.configurations
        .map((c: any) => `${c.boxes}箱×${c.unitsPerBox}件/箱`)
        .join('+');
      const total = r.configurations.reduce(
        (s: number, c: any) => s + c.boxes * c.unitsPerBox, 0,
      );
      return `${parts}=${total}件`;
    }
    return `${r.boxes}箱×${r.unitsPerBox}件/箱=${r.quantity}件`;
  }

  /** +N箱×U件/箱=+T件 | +N箱（无箱规）| +T件 */
  private describeInDelta(boxes: number, unitsPerBox: number, boxesOnlyMode?: boolean): string {
    if (boxesOnlyMode) return `+${boxes}箱（无箱规）`;
    const upb = unitsPerBox > 0 ? unitsPerBox : 1;
    if (upb > 1) return `+${boxes}箱×${upb}件/箱=+${boxes * upb}件`;
    return `+${boxes * upb}件`;
  }

  /** -N箱×U件/箱=-T件 | -T件 */
  private describeOutDelta(quantity: number, configs?: { boxes: number; unitsPerBox: number }[]): string {
    if (configs && configs.length > 0) {
      const parts = configs.map(c => `${c.boxes}箱×${c.unitsPerBox}件/箱`).join('+');
      return `-${parts}=-${quantity}件`;
    }
    return `-${quantity}件`;
  }

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
    if ((sku as any).status === 'archived') {
      throw new BadRequestException(`SKU ${dto.skuCode} 已归档，不允许录入新库存`);
    }

    const location = await this.locationModel.findById(dto.locationId);
    if (!location) throw new NotFoundException('库位不存在');

    const existing = await this.inventoryModel.findOne({
      skuId: sku._id,
      locationId: new Types.ObjectId(dto.locationId),
      stockStatus: { $in: ['confirmed', 'pending_count', 'temporary'] },
    });
    if (existing) throw new BadRequestException(`${dto.skuCode} 在此库位已有库存记录`);

    // Remove stale zero-qty tombstone records left by prior merge/split operations.
    // These hold the unique index slot (skuId+locationId) but carry no active stock.
    await this.inventoryModel.deleteMany({
      skuId: sku._id,
      locationId: new Types.ObjectId(dto.locationId),
      stockStatus: { $in: ['completed_merge', 'completed_split'] },
    });

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

    const qtyDesc    = this.describeQty(record);
    const modeLabel  = record.quantityUnknown ? '待清点'
      : (record as any).boxesOnlyMode ? '仅箱数'
      : (record.configurations?.length ?? 0) > 0 ? '按箱规'
      : record.unitsPerBox > 1 ? '按箱规'
      : '按数量';
    const statusTag  = stockStatus === 'pending_count' ? ' (暂存)' : '';
    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'add',
      entity: 'inventory',
      businessAction: stockStatus === 'pending_count' ? '暂存' : '录入',
      description: `录入: ${sku.sku} @ ${location.code} [${modeLabel}] ${qtyDesc}${statusTag}`,
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

    const beforeDesc = this.describeQty(record);

    if (dto.boxes !== undefined) record.boxes = dto.boxes;
    if (dto.unitsPerBox !== undefined) record.unitsPerBox = dto.unitsPerBox;
    if (dto.pendingCount !== undefined) {
      record.stockStatus = dto.pendingCount ? 'pending_count' : 'confirmed';
      record.quantityUnknown = false;
    }
    if (dto.boxesOnlyMode !== undefined) record.boxesOnlyMode = dto.boxesOnlyMode;
    record.quantity = this.computeQuantity(record);
    await record.save();

    const afterDesc = this.describeQty(record);
    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'inventory',
      businessAction: '结构修改',
      description: `结构修改: ${(record.skuId as any).sku} @ ${(record.locationId as any).code} [调前:${beforeDesc}] → [调后:${afterDesc}]`,
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
    const deletedQtyDesc = this.describeQty(record);

    await this.inventoryModel.findByIdAndDelete(id);

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'delete',
      entity: 'inventory',
      businessAction: '删除库存',
      description: `删除库存: ${skuCode} @ ${locationCode} [原:${deletedQtyDesc}]`,
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
    pendingCount?: boolean;
  }, user: any) {
    const sku = await this.skuModel.findOne({ sku: dto.skuCode.toUpperCase() });
    if (!sku) throw new NotFoundException(`SKU ${dto.skuCode} 不存在`);
    if ((sku as any).status === 'archived') {
      throw new BadRequestException(`SKU ${dto.skuCode} 已归档，不允许新入库`);
    }

    const location = await this.locationModel.findById(dto.locationId);
    if (!location) throw new NotFoundException('库位不存在');

    const stockStatus = dto.pendingCount ? 'pending_count' : 'confirmed';

    const existing = await this.inventoryModel.findOne({
      skuId: sku._id,
      locationId: new Types.ObjectId(dto.locationId),
      stockStatus: { $in: ['confirmed', 'pending_count', 'temporary'] },
    });

    if (existing) {
      if (existing.configurations && existing.configurations.length > 0) {
        // Record has multi-spec configs — merge new stock into matching spec or add a new entry
        const newUnitsPerBox = dto.unitsPerBox ?? 1;
        const matchIdx = existing.configurations.findIndex(c => c.unitsPerBox === newUnitsPerBox);
        if (matchIdx >= 0) {
          existing.configurations = existing.configurations.map((c, i) =>
            i === matchIdx ? { boxes: c.boxes + dto.boxes, unitsPerBox: c.unitsPerBox } : c
          );
        } else {
          existing.configurations = [...existing.configurations, { boxes: dto.boxes, unitsPerBox: newUnitsPerBox }];
        }
        existing.markModified('configurations');
        existing.boxes = existing.configurations.reduce((s, c) => s + c.boxes, 0);
      } else {
        // Flat model — just add boxes
        existing.boxes = (existing.boxes ?? 0) + dto.boxes;
        if (dto.unitsPerBox) existing.unitsPerBox = dto.unitsPerBox;
      }
      if (dto.boxesOnlyMode !== undefined) existing.boxesOnlyMode = dto.boxesOnlyMode;
      existing.stockStatus = stockStatus;
      existing.quantityUnknown = false;
      existing.quantity = this.computeQuantity(existing);
      await existing.save();
    } else {
      // Remove any stale completed_* tombstone before creating a fresh record
      await this.inventoryModel.deleteMany({
        skuId: sku._id,
        locationId: new Types.ObjectId(dto.locationId),
        stockStatus: { $in: ['completed_merge', 'completed_split'] },
      });
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
        stockStatus,
        note: dto.note,
      });
    }

    const inDelta = this.describeInDelta(dto.boxes, dto.unitsPerBox ?? 1, dto.boxesOnlyMode);
    const addedQty = dto.boxes * (dto.unitsPerBox ?? 1);
    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'inventory',
      businessAction: '入库',
      description: `入库: ${sku.sku} @ ${location.code} ${inDelta}`,
      details: {
        skuCode: sku.sku,
        locationCode: location.code,
        addedQty,
        boxes: dto.boxes,
        unitsPerBox: dto.unitsPerBox ?? 1,
      },
    });

    await this.txModel.create({
      skuCode: sku.sku,
      locationId: new Types.ObjectId(dto.locationId),
      locationCode: location.code,
      type: 'IN',
      quantity: dto.boxes * (dto.unitsPerBox ?? 1),
      boxes: dto.boxes,
      unitsPerBox: dto.unitsPerBox ?? 1,
      note: dto.note,
      businessAction: '入库',
      operatorId: new Types.ObjectId(user._id.toString()),
      operatorName: user.name,
    });

    return { message: '入库成功' };
  }

  async stockOut(dto: {
    skuCode: string;
    locationId: string;
    quantity: number;
    configurations?: { boxes: number; unitsPerBox: number }[]; // per-spec removal (按箱规 mode)
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
      // 按箱规出库: build the source configs (prefer record.configurations, fall back to record.boxes/unitsPerBox)
      const sourceConfigs: { boxes: number; unitsPerBox: number }[] =
        record.configurations?.length > 0
          ? record.configurations
          : (record.boxes > 0 ? [{ boxes: record.boxes, unitsPerBox: record.unitsPerBox ?? 1 }] : []);

      // validate each spec before subtracting
      for (const toRemove of dto.configurations) {
        const existing = sourceConfigs.find(c => c.unitsPerBox === toRemove.unitsPerBox);
        const available = existing?.boxes ?? 0;
        if (toRemove.boxes > available) {
          throw new BadRequestException(
            `库存不足：${toRemove.unitsPerBox}件/箱 当前 ${available} 箱，出库 ${toRemove.boxes} 箱`
          );
        }
      }

      // subtract
      const updated = sourceConfigs
        .map(existing => {
          const toRemove = dto.configurations!.find(c => c.unitsPerBox === existing.unitsPerBox);
          return { boxes: existing.boxes - (toRemove?.boxes ?? 0), unitsPerBox: existing.unitsPerBox };
        })
        .filter(c => c.boxes > 0);
      record.configurations = updated;
      record.markModified('configurations');
      record.boxes = updated.reduce((s, c) => s + c.boxes, 0);
      record.quantity = this.computeQuantity(record);
    } else {
      // 按总数量出库: validate against total quantity first
      if (record.quantity < dto.quantity) {
        throw new BadRequestException(`库存不足：当前 ${record.quantity} 件，出库 ${dto.quantity} 件`);
      }
      const newQty = Math.max(0, record.quantity - dto.quantity);
      const newBoxes = record.unitsPerBox > 0 ? Math.floor(newQty / record.unitsPerBox) : 0;
      record.configurations = [];
      record.markModified('configurations');
      record.boxes = newBoxes;
      record.quantity = newQty;
    }
    await record.save();

    const outDelta = this.describeOutDelta(dto.quantity, dto.configurations);
    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'inventory',
      businessAction: '出库',
      description: `出库: ${sku.sku} @ ${location.code} ${outDelta}`,
      details: {
        skuCode: sku.sku,
        locationCode: location.code,
        reducedQty: dto.quantity,
        remainingQty: record.quantity,
        configurations: dto.configurations,
      },
    });

    await this.txModel.create({
      skuCode: sku.sku,
      locationId: new Types.ObjectId(dto.locationId),
      locationCode: location.code,
      type: 'OUT',
      quantity: dto.quantity,
      note: dto.note,
      businessAction: '出库',
      operatorId: new Types.ObjectId(user._id.toString()),
      operatorName: user.name,
    });

    return { message: '出库成功' };
  }

  async stockAdjust(dto: {
    skuCode: string;
    locationId: string;
    quantity?: number;
    configurations?: { boxes: number; unitsPerBox: number }[];
    adjustMode?: 'qty' | 'configs' | 'boxes_only'; // for audit description clarity
    note?: string;
  }, user: any) {
    if (!dto.note || dto.note.trim() === '') {
      throw new BadRequestException('库存调整必须填写备注说明原因');
    }

    const sku = await this.skuModel.findOne({ sku: dto.skuCode.toUpperCase() });
    if (!sku) throw new NotFoundException(`SKU ${dto.skuCode} 不存在`);

    const location = await this.locationModel.findById(dto.locationId);
    if (!location) throw new NotFoundException('库位不存在');

    const record = await this.inventoryModel.findOne({
      skuId: sku._id,
      locationId: new Types.ObjectId(dto.locationId),
    });
    if (!record) throw new NotFoundException('库存记录不存在');

    // Snapshot before (full structure for rich description)
    const beforeDesc = this.describeQty(record);
    const before = {
      quantity: record.quantity,
      boxes: record.boxes,
      unitsPerBox: record.unitsPerBox,
      configurations: JSON.stringify(record.configurations ?? []),
    };

    if (dto.configurations && dto.configurations.length > 0) {
      record.configurations = dto.configurations;
      record.markModified('configurations');
      record.boxes = dto.configurations.reduce((s, c) => s + c.boxes, 0);
      record.quantity = this.computeQuantity({ configurations: dto.configurations });
    } else if (dto.quantity !== undefined) {
      record.quantity = dto.quantity;
      record.boxes = record.unitsPerBox > 0 ? Math.floor(dto.quantity / record.unitsPerBox) : 0;
      record.configurations = [];
      record.markModified('configurations');
    }
    record.stockStatus = 'confirmed';
    record.quantityUnknown = false;
    if (dto.note) record.note = dto.note;
    await record.save();

    const modeLabel = dto.adjustMode === 'configs' ? '箱规调整'
      : dto.adjustMode === 'boxes_only' ? '箱数调整'
      : '数量调整';
    const afterDesc = this.describeQty(record);

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'inventory',
      businessAction: '调整',
      description: `${modeLabel}: ${sku.sku} @ ${location.code} [调前:${beforeDesc}] → [调后:${afterDesc}] 原因:${dto.note}`,
      details: {
        skuCode: sku.sku,
        locationCode: location.code,
        beforeQty: before.quantity,
        afterQty: record.quantity,
        note: dto.note,
      },
    });

    await this.txModel.create({
      skuCode: sku.sku,
      locationId: new Types.ObjectId(dto.locationId),
      locationCode: location.code,
      type: 'ADJUST',
      quantity: record.quantity,
      boxes: record.boxes,
      unitsPerBox: record.unitsPerBox,
      note: dto.note,
      businessAction: '调整',
      operatorId: new Types.ObjectId(user._id.toString()),
      operatorName: user.name,
    });

    return { message: '调整成功', quantity: record.quantity, boxes: record.boxes };
  }

  async correctSku(dto: {
    inventoryId: string;
    newSkuCode: string;
    note: string;
    allowMerge?: boolean;
  }, user: any) {
    if (!dto.note || dto.note.trim() === '') {
      throw new BadRequestException('SKU更正必须填写原因');
    }

    const record = await this.inventoryModel.findById(dto.inventoryId);
    if (!record) throw new NotFoundException('库存记录不存在');

    const location = await this.locationModel.findById(record.locationId);
    if (!location) throw new NotFoundException('库位不存在');

    const newSku = await this.skuModel.findOne({ sku: dto.newSkuCode.toUpperCase() });
    if (!newSku) throw new NotFoundException(`SKU ${dto.newSkuCode} 不存在`);

    const conflict = await this.inventoryModel.findOne({
      skuId: newSku._id,
      locationId: record.locationId,
    });
    const hasConflict = !!conflict && conflict._id.toString() !== record._id.toString();
    const oldSkuCode = record.skuCode;

    // ── 有冲突时先校验源记录是否可换算为件数 ──
    if (hasConflict) {
      if (record.quantityUnknown) {
        throw new BadRequestException(
          '当前记录数量待清点，无法换算总件数，请先补充库存信息后再合并',
        );
      }
      if (record.boxesOnlyMode) {
        throw new BadRequestException(
          '当前记录只有箱数，没有每箱件数，无法换算总件数，请先补充箱规或件数后再合并',
        );
      }
    }

    // ── 有冲突且未确认合并 → 返回特殊错误让前端弹确认框 ──
    if (hasConflict && !dto.allowMerge) {
      const srcDesc = this.describeQty(record);
      const tgtDesc = this.describeQty(conflict);
      throw new BadRequestException({
        code: 'MERGE_REQUIRED',
        message: `${newSku.sku} 在库位 ${location.code} 已有库存（${tgtDesc}）。\n是否将 ${oldSkuCode}（${srcDesc}）合并入 ${newSku.sku}？`,
        srcQtyDesc: srcDesc,
        tgtQtyDesc: tgtDesc,
      });
    }

    // ── 有冲突 + 确认合并 ──
    if (hasConflict && dto.allowMerge) {
      const srcDesc = this.describeQty(record);
      const tgtDesc = this.describeQty(conflict);

      // Build normalised config arrays for both sides
      const srcConfigs = this.effectiveConfigs(record)!; // validated above, cannot be null
      const tgtConfigs = this.effectiveConfigs(conflict) ?? [];

      // Merge: add each src spec into tgt, grouped by unitsPerBox
      const merged = tgtConfigs.map(c => ({ boxes: c.boxes, unitsPerBox: c.unitsPerBox }));
      for (const sc of srcConfigs) {
        const idx = merged.findIndex(tc => tc.unitsPerBox === sc.unitsPerBox);
        if (idx >= 0) {
          merged[idx].boxes += sc.boxes;
        } else {
          merged.push({ boxes: sc.boxes, unitsPerBox: sc.unitsPerBox });
        }
      }

      // Write merged configs back to target record
      conflict.configurations = merged as any;
      conflict.markModified('configurations');
      conflict.quantity = merged.reduce((s, c) => s + c.boxes * c.unitsPerBox, 0);
      conflict.boxes    = merged.reduce((s, c) => s + c.boxes, 0);
      // Sync flat unitsPerBox if single-spec result
      if (merged.length === 1) conflict.unitsPerBox = merged[0].unitsPerBox;
      conflict.stockStatus = 'confirmed';
      await conflict.save();

      // Zero out source record (preserved, not deleted)
      record.stockStatus    = 'completed_merge';
      record.quantity       = 0;
      record.boxes          = 0;
      record.configurations = [] as any;
      record.markModified('configurations');
      await record.save();

      const tgtDescAfter = this.describeQty(conflict);

      const description =
        `SKU更正并合并: ${oldSkuCode}(${srcDesc}) → ${newSku.sku} @ ${location.code}` +
        ` [目标合并前:${tgtDesc} / 合并后:${tgtDescAfter}] 原因:${dto.note}`;

      await this.historyService.log({
        userId: user._id.toString(),
        userName: user.name,
        action: 'edit',
        entity: 'inventory',
        businessAction: 'SKU更正并合并',
        description,
      });

      await this.txModel.create({
        skuCode: newSku.sku,
        locationId: conflict.locationId,
        locationCode: location.code,
        type: 'ADJUST',
        quantity: conflict.quantity,
        boxes: conflict.boxes,
        unitsPerBox: conflict.unitsPerBox,
        note: `SKU更正并合并 ${oldSkuCode}(${srcDesc})→${newSku.sku}: ${dto.note}`,
        businessAction: 'SKU更正并合并',
        operatorId: new Types.ObjectId(user._id.toString()),
        operatorName: user.name,
      });

      return {
        message: 'SKU更正并合并成功',
        oldSkuCode,
        newSkuCode: newSku.sku,
        mergedQty: conflict.quantity,
        mergedBoxes: conflict.boxes,
      };
    }

    // ── 无冲突：普通更正 ──
    record.skuId   = newSku._id as any;
    record.skuCode = newSku.sku;
    await record.save();

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'inventory',
      businessAction: 'SKU更正',
      description: `SKU更正: ${oldSkuCode} → ${newSku.sku} @ ${location.code} [库存:${this.describeQty(record)} 保留] 原因:${dto.note}`,
    });

    await this.txModel.create({
      skuCode: newSku.sku,
      locationId: record.locationId,
      locationCode: location.code,
      type: 'ADJUST',
      quantity: record.quantity,
      boxes: record.boxes,
      unitsPerBox: record.unitsPerBox,
      note: `SKU更正 ${oldSkuCode}→${newSku.sku}: ${dto.note}`,
      businessAction: 'SKU更正',
      operatorId: new Types.ObjectId(user._id.toString()),
      operatorName: user.name,
    });

    return { message: 'SKU更正成功', oldSkuCode, newSkuCode: newSku.sku };
  }

  // ─── Transaction history ──────────────────────────────────────────────────────

  async getTransactions(params: {
    skuCode?: string;
    locationId?: string;
    type?: string;
    startDate?: string;
    endDate?: string;
    page?: number;
    limit?: number;
  }) {
    const filter: any = {};
    if (params.skuCode) filter.skuCode = params.skuCode.toUpperCase();
    if (params.locationId) filter.locationId = new Types.ObjectId(params.locationId);
    if (params.type) filter.type = params.type.toUpperCase();
    if (params.startDate || params.endDate) {
      filter.createdAt = {};
      if (params.startDate) filter.createdAt.$gte = new Date(params.startDate);
      if (params.endDate) {
        const end = new Date(params.endDate);
        end.setHours(23, 59, 59, 999);
        filter.createdAt.$lte = end;
      }
    }

    const page = params.page ?? 1;
    const limit = Math.min(params.limit ?? 20, 100);

    const [records, total] = await Promise.all([
      this.txModel.find(filter).sort({ createdAt: -1 }).skip((page - 1) * limit).limit(limit).lean(),
      this.txModel.countDocuments(filter),
    ]);

    return { records, total, page, limit };
  }

  async confirmPending(dto: {
    inventoryId: string;
    newSkuCode?: string;
    note: string;
  }, user: any) {
    if (!dto.note || dto.note.trim() === '') {
      throw new BadRequestException('确认为正式库存必须填写原因');
    }

    const record = await this.inventoryModel.findById(dto.inventoryId);
    if (!record) throw new NotFoundException('库存记录不存在');

    const isPending =
      record.stockStatus === 'pending_count' ||
      record.stockStatus === 'temporary';
    if (!isPending) {
      throw new BadRequestException('该库存记录不是暂存状态，无需确认');
    }

    const location = await this.locationModel.findById(record.locationId);
    if (!location) throw new NotFoundException('库位不存在');

    const oldSkuCode = record.skuCode;
    let finalSkuCode = oldSkuCode;

    // Optional SKU correction at the same time
    if (dto.newSkuCode && dto.newSkuCode.toUpperCase() !== oldSkuCode.toUpperCase()) {
      const newSku = await this.skuModel.findOne({ sku: dto.newSkuCode.toUpperCase() });
      if (!newSku) throw new NotFoundException(`SKU ${dto.newSkuCode} 不存在`);

      const conflict = await this.inventoryModel.findOne({
        skuId: newSku._id,
        locationId: record.locationId,
        _id: { $ne: record._id },
      });
      if (conflict) {
        throw new BadRequestException(
          `${dto.newSkuCode} 在库位 ${location.code} 已存在库存记录，无法合并`,
        );
      }

      record.skuId = newSku._id as any;
      record.skuCode = newSku.sku;
      finalSkuCode = newSku.sku;
    }

    record.stockStatus = 'confirmed';
    record.quantityUnknown = false;
    await record.save();

    const skuChanged = finalSkuCode !== oldSkuCode;
    const descSku  = skuChanged ? `${oldSkuCode}→${finalSkuCode}` : finalSkuCode;
    const qtyDesc  = this.describeQty(record);
    const skuTag   = skuChanged ? ' (SKU已更正)' : '';

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'inventory',
      businessAction: '暂存转正式',
      description: `暂存转正式: ${descSku} @ ${location.code} [${qtyDesc}]${skuTag} 原因:${dto.note}`,
    });

    await this.txModel.create({
      skuCode: finalSkuCode,
      locationId: record.locationId,
      locationCode: location.code,
      type: 'ADJUST',
      quantity: record.quantity,
      boxes: record.boxes,
      unitsPerBox: record.unitsPerBox,
      note: `暂存转正式: ${dto.note}`,
      businessAction: '暂存转正式',
      operatorId: new Types.ObjectId(user._id.toString()),
      operatorName: user.name,
    });

    return { message: '已确认为正式库存', skuCode: finalSkuCode };
  }

  async splitPending(dto: {
    inventoryId: string;
    splits: Array<{
      skuCode: string;
      boxes: number;
      unitsPerBox: number;
      totalQty?: number; // qty-mode split: total piece count (boxes=0 sentinel)
      configurations?: Array<{ boxes: number; unitsPerBox: number }>;
    }>;
    note: string;
  }, user: any) {
    if (!dto.note || dto.note.trim() === '') {
      throw new BadRequestException('拆分必须填写原因');
    }
    if (!dto.splits || dto.splits.length < 1) {
      throw new BadRequestException('至少需要一个拆分目标');
    }

    const record = await this.inventoryModel.findById(dto.inventoryId);
    if (!record) throw new NotFoundException('库存记录不存在');

    const isPending =
      record.stockStatus === 'pending_count' ||
      record.stockStatus === 'temporary';
    if (!isPending) {
      throw new BadRequestException('该库存记录不是暂存状态');
    }

    const location = await this.locationModel.findById(record.locationId);
    if (!location) throw new NotFoundException('库位不存在');

    // Normalize qty-mode splits: frontend sends boxes=0,unitsPerBox=0,totalQty=N
    // Convert to boxes=1,unitsPerBox=N so all downstream logic is uniform.
    const splits = dto.splits.map(s =>
      (s.totalQty && s.totalQty > 0 && s.boxes === 0)
        ? { ...s, boxes: 1, unitsPerBox: s.totalQty }
        : s,
    );

    // When the source is boxes-only, validate in box space; otherwise validate in piece space.
    const isSourceBoxesOnly = !!(record as any).boxesOnlyMode;
    const originalAmount = isSourceBoxesOnly ? (record.boxes ?? 0) : record.quantity;
    const amountUnit = isSourceBoxesOnly ? '箱' : '件';

    const splitTotal = splits.reduce((sum, s) => {
      if (isSourceBoxesOnly) {
        return sum + s.boxes; // box-space validation
      }
      if (s.configurations && s.configurations.length > 0) {
        return sum + s.configurations.reduce((cs, c) => cs + c.boxes * c.unitsPerBox, 0);
      }
      return sum + s.boxes * (s.unitsPerBox ?? 1);
    }, 0);

    if (splitTotal !== originalAmount) {
      throw new BadRequestException(
        `拆分总${amountUnit} ${splitTotal} ${amountUnit}与原暂存数量 ${originalAmount} ${amountUnit}不匹配`,
      );
    }

    const createdSkuCodes: string[] = [];
    // Collect per-target qty descriptions for the history log
    const splitDetails: Array<{ skuCode: string; qtyDesc: string; boxes: number; qty: number; boxesOnly: boolean }> = [];

    for (const split of splits) {
      const sku = await this.skuModel.findOne({ sku: split.skuCode.toUpperCase() });
      if (!sku) throw new NotFoundException(`SKU ${split.skuCode} 不存在`);

      // A split target is boxes-only when the source is boxes-only and no per-box count is given.
      const splitIsBoxesOnly = isSourceBoxesOnly && !(split.unitsPerBox && split.unitsPerBox > 0);
      const splitQty = splitIsBoxesOnly ? 0
        : split.configurations?.length
          ? split.configurations.reduce((s, c) => s + c.boxes * c.unitsPerBox, 0)
          : split.boxes * (split.unitsPerBox ?? 1);

      const splitBoxes = split.configurations?.length
        ? split.configurations.reduce((s, c) => s + c.boxes, 0)
        : split.boxes;
      const targetQtyDesc = this.describeQty({
        quantityUnknown: false,
        boxesOnlyMode: splitIsBoxesOnly,
        boxes: splitBoxes,
        unitsPerBox: split.unitsPerBox || 1,
        configurations: split.configurations ?? [],
        quantity: splitQty,
      });
      splitDetails.push({ skuCode: sku.sku, qtyDesc: targetQtyDesc, boxes: splitBoxes, qty: splitQty, boxesOnly: splitIsBoxesOnly });

      const existing = await this.inventoryModel.findOne({
        skuId: sku._id,
        locationId: record.locationId,
      });

      if (existing) {
        // Merge into existing confirmed record
        if (split.configurations?.length) {
          for (const sc of split.configurations) {
            const idx = existing.configurations.findIndex(
              (ec) => ec.unitsPerBox === sc.unitsPerBox,
            );
            if (idx >= 0) {
              existing.configurations[idx].boxes += sc.boxes;
            } else {
              existing.configurations.push({ boxes: sc.boxes, unitsPerBox: sc.unitsPerBox });
            }
          }
          existing.markModified('configurations');
          existing.quantity += splitQty;
          existing.boxes = existing.configurations.reduce((s, c) => s + c.boxes, 0);
        } else {
          existing.boxes += split.boxes;
          existing.quantity += splitQty;
        }
        existing.stockStatus = 'confirmed';
        await existing.save();
      } else {
        // Create new confirmed record
        const configs = split.configurations?.length ? split.configurations : [];
        await this.inventoryModel.create({
          skuId: sku._id,
          skuCode: sku.sku,
          locationId: record.locationId,
          boxes: split.configurations?.length
            ? split.configurations.reduce((s, c) => s + c.boxes, 0)
            : split.boxes,
          unitsPerBox: split.configurations?.length ? 1 : (split.unitsPerBox || 1),
          configurations: configs,
          quantity: splitQty,
          stockStatus: 'confirmed',
          quantityUnknown: false,
          boxesOnlyMode: splitIsBoxesOnly,
        });
      }

      createdSkuCodes.push(sku.sku);

      await this.txModel.create({
        skuCode: sku.sku,
        locationId: record.locationId,
        locationCode: location.code,
        type: 'IN',
        quantity: splitQty,
        boxes: split.configurations?.length
          ? split.configurations.reduce((s, c) => s + c.boxes, 0)
          : split.boxes,
        unitsPerBox: split.unitsPerBox,
        note: `暂存拆分自 ${record.skuCode}: ${dto.note}`,
        businessAction: '暂存拆分',
        operatorId: new Types.ObjectId(user._id.toString()),
        operatorName: user.name,
      });
    }

    // Zero out original record
    record.stockStatus = 'completed_split';
    record.quantity = 0;
    record.boxes = 0;
    record.configurations = [];
    record.markModified('configurations');
    await record.save();

    const sourceQtyDesc = isSourceBoxesOnly
      ? `${originalAmount}箱（无箱规）`
      : `${originalAmount}${amountUnit}`;
    const splitSummary = splitDetails
      .map(d => `${d.skuCode}:${d.qtyDesc}`)
      .join(', ');
    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'inventory',
      businessAction: '暂存拆分',
      description: `暂存拆分: ${record.skuCode} @ ${location.code} [原${sourceQtyDesc}] → ${splitSummary} 原因:${dto.note}`,
      details: {
        source: { skuCode: record.skuCode, locationCode: location.code, qtyDesc: sourceQtyDesc },
        targets: splitDetails.map(d => ({ skuCode: d.skuCode, qtyDesc: d.qtyDesc, boxes: d.boxes, qty: d.qty, boxesOnly: d.boxesOnly })),
        note: dto.note,
      },
    });

    return {
      message: '拆分成功',
      originalSkuCode: record.skuCode,
      createdSkuCodes,
    };
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
