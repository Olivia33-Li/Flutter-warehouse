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

  /**
   * Compute quantity for the new stock model:
   *   quantity = loosePcs + sum(configs.boxes * configs.unitsPerBox)
   * unconfiguredCartons are NOT counted in quantity.
   */
  private computeQtyFromStructure(fields: {
    loosePcs?: number;
    configurations?: { boxes: number; unitsPerBox: number }[];
  }): number {
    return (fields.loosePcs ?? 0) +
      (fields.configurations ?? []).reduce((s, c) => s + c.boxes * c.unitsPerBox, 0);
  }

  /**
   * Compute total carton count:
   *   totalCartons = unconfiguredCartons + sum(configs.boxes)
   * Stored in the `boxes` field for backward compatibility.
   */
  private computeTotalCartons(fields: {
    configurations?: { boxes: number; unitsPerBox: number }[];
    unconfiguredCartons?: number;
  }): number {
    return (fields.unconfiguredCartons ?? 0) +
      (fields.configurations ?? []).reduce((s, c) => s + c.boxes, 0);
  }

  private formatRecord(r: any) {
    const sku = r.skuId as any;
    const skuCode = r.skuCode || sku?.sku || '';
    return {
      ...r,
      skuCode,
      skuId: sku?._id?.toString() ?? r.skuId?.toString(),
      skuName: sku?.name,
      loosePcs: r.loosePcs ?? 0,
      unconfiguredCartons: r.unconfiguredCartons ?? 0,
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
    const [invRes, skuRes, locRes, txRes, importRes, auditLogs] = await Promise.all([
      this.inventoryModel.deleteMany({}),
      this.skuModel.deleteMany({}),
      this.locationModel.deleteMany({}),
      this.txModel.deleteMany({}),
      this.importLogModel.deleteMany({}),
      this.historyService.clearAll(),
    ]);
    return {
      deleted: {
        inventories: invRes.deletedCount ?? 0,
        skus: skuRes.deletedCount ?? 0,
        locations: locRes.deletedCount ?? 0,
        transactions: txRes.deletedCount ?? 0,
        importLogs: importRes.deletedCount ?? 0,
        auditLogs,
      },
    };
  }

  // ─── Transactions ─────────────────────────────────────────────────────────────

  async stockIn(dto: {
    skuCode: string;
    locationId: string;
    // by-carton single spec
    boxes?: number;
    unitsPerBox?: number;
    // by-carton multi-spec
    configurations?: { boxes: number; unitsPerBox: number }[];
    // cartons-only (no unitsPerBox) → unconfiguredCartons
    boxesOnlyMode?: boolean;
    // by-qty (loose pieces) → loosePcs
    addQuantity?: number;
    // common
    note?: string;
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

    // ── Mode detection ────────────────────────────────────────────────────────
    // inConfigs  → by-carton: merge into configurations, counts toward quantity
    // inBoxesOnly → cartons-only: add to unconfiguredCartons, NOT in quantity
    // addQty     → by-qty: add to loosePcs, counts toward quantity
    // No unitsPerBox default. Missing unitsPerBox with boxes → cartons-only.
    let inConfigs: { boxes: number; unitsPerBox: number }[] | null = null;
    let inBoxesOnly: number | null = null;
    let addQty: number | null = null;

    if (dto.configurations && dto.configurations.length > 0) {
      for (const c of dto.configurations) {
        if (c.boxes <= 0) throw new BadRequestException('入库箱数不能为零或负数');
        if (c.unitsPerBox <= 0) throw new BadRequestException('箱规必须大于零');
      }
      inConfigs = dto.configurations;
    } else if (!dto.boxesOnlyMode && dto.boxes !== undefined && dto.unitsPerBox !== undefined && dto.unitsPerBox > 0) {
      if (dto.boxes <= 0) throw new BadRequestException('入库箱数不能为零或负数');
      inConfigs = [{ boxes: dto.boxes, unitsPerBox: dto.unitsPerBox }];
    } else if (dto.boxesOnlyMode || (dto.boxes !== undefined && !dto.unitsPerBox)) {
      // No unitsPerBox → unconfiguredCartons. Never default unitsPerBox to 1.
      const n = dto.boxes ?? 0;
      if (n <= 0) throw new BadRequestException('入库箱数不能为零或负数');
      inBoxesOnly = n;
    } else if (dto.addQuantity !== undefined) {
      if (dto.addQuantity <= 0) throw new BadRequestException('入库件数不能为零或负数');
      addQty = dto.addQuantity;
    } else {
      throw new BadRequestException('入库数量不能为零');
    }

    // ── Merge configs helper ─────────────────────────────────────────────────
    const mergeConfigs = (
      existing: { boxes: number; unitsPerBox: number }[],
      incoming: { boxes: number; unitsPerBox: number }[],
    ): { boxes: number; unitsPerBox: number }[] => {
      const result = [...existing];
      for (const spec of incoming) {
        const idx = result.findIndex(c => c.unitsPerBox === spec.unitsPerBox);
        if (idx >= 0) {
          result[idx] = { boxes: result[idx].boxes + spec.boxes, unitsPerBox: spec.unitsPerBox };
        } else {
          result.push({ ...spec });
        }
      }
      return result;
    };

    const existing = await this.inventoryModel.findOne({
      skuId: sku._id,
      locationId: new Types.ObjectId(dto.locationId),
      stockStatus: { $in: ['confirmed', 'pending_count', 'temporary'] },
    });

    if (existing) {
      if (inConfigs) {
        // by-carton: merge into configurations (existing loosePcs / unconfiguredCartons untouched)
        existing.configurations = mergeConfigs(existing.configurations ?? [], inConfigs);
        existing.markModified('configurations');
        existing.boxesOnlyMode = false;
      } else if (inBoxesOnly !== null) {
        // cartons-only: accumulate in unconfiguredCartons only, never touch quantity
        existing.unconfiguredCartons = (existing.unconfiguredCartons ?? 0) + inBoxesOnly;
        // boxesOnlyMode = true only when record has nothing else
        existing.boxesOnlyMode =
          (existing.configurations ?? []).length === 0 && (existing.loosePcs ?? 0) === 0;
      } else if (addQty !== null) {
        // by-qty: accumulate in loosePcs
        existing.loosePcs = (existing.loosePcs ?? 0) + addQty;
        existing.boxesOnlyMode = false;
      }
      existing.stockStatus = stockStatus;
      existing.quantityUnknown = false;
      // Recompute derived summary fields
      existing.quantity = this.computeQtyFromStructure(existing);
      existing.boxes    = this.computeTotalCartons(existing);
      const cfgs = existing.configurations ?? [];
      existing.unitsPerBox = cfgs.length === 1 ? cfgs[0].unitsPerBox : 0;
      await existing.save();
    } else {
      // ── New record ───────────────────────────────────────────────────────────
      await this.inventoryModel.deleteMany({
        skuId: sku._id,
        locationId: new Types.ObjectId(dto.locationId),
        stockStatus: { $in: ['completed_merge', 'completed_split'] },
      });

      const configurations = inConfigs ?? [];
      const loosePcs       = addQty ?? 0;
      const unconfiguredCartons = inBoxesOnly ?? 0;

      await this.inventoryModel.create({
        skuId: sku._id,
        skuCode: sku.sku,
        locationId: new Types.ObjectId(dto.locationId),
        configurations,
        loosePcs,
        unconfiguredCartons,
        boxes: this.computeTotalCartons({ configurations, unconfiguredCartons }),
        unitsPerBox: configurations.length === 1 ? configurations[0].unitsPerBox : 0,
        quantity: this.computeQtyFromStructure({ loosePcs, configurations }),
        boxesOnlyMode: inBoxesOnly !== null && inConfigs === null && addQty === null,
        quantityUnknown: false,
        stockStatus,
        note: dto.note,
      });
    }

    // ── Audit log ────────────────────────────────────────────────────────────
    let inDelta: string;
    let addedQty: number;
    let logBoxes: number;

    if (inConfigs) {
      addedQty = inConfigs.reduce((s, c) => s + c.boxes * c.unitsPerBox, 0);
      logBoxes  = inConfigs.reduce((s, c) => s + c.boxes, 0);
      if (inConfigs.length === 1) {
        inDelta = `+${inConfigs[0].boxes}箱×${inConfigs[0].unitsPerBox}件/箱=+${addedQty}件`;
      } else {
        const parts = inConfigs.map(c => `+${c.boxes}箱×${c.unitsPerBox}件/箱`).join('+');
        inDelta = `${parts}=+${addedQty}件`;
      }
    } else if (inBoxesOnly !== null) {
      inDelta  = `+${inBoxesOnly}箱（无箱规）`;
      addedQty = 0;
      logBoxes  = inBoxesOnly;
    } else {
      inDelta  = `+${addQty!}件`;
      addedQty = addQty!;
      logBoxes  = 0;
    }

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
        boxes: logBoxes,
        configurations: inConfigs ?? undefined,
        ...(inBoxesOnly !== null ? { boxesOnlyMode: true, unconfiguredCartons: inBoxesOnly } : {}),
        ...(addQty !== null ? { loosePcs: addQty } : {}),
      },
    });

    await this.txModel.create({
      skuCode: sku.sku,
      locationId: new Types.ObjectId(dto.locationId),
      locationCode: location.code,
      type: 'IN',
      quantity: addedQty,
      boxes: logBoxes,
      unitsPerBox: inConfigs?.length === 1 ? inConfigs[0].unitsPerBox : undefined,
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
    quantity?: number;              // by-qty: deduct from loosePcs only
    configurations?: { boxes: number; unitsPerBox: number }[];  // by-carton: deduct from configurations
    unconfiguredCartons?: number;   // cartons-only: deduct from unconfiguredCartons
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

    let outDeltaStr: string;
    let reducedQty = 0;

    if (dto.configurations && dto.configurations.length > 0) {
      // ── by-carton: deduct from configurations ────────────────────────────────
      const sourceConfigs = record.configurations ?? [];
      for (const toRemove of dto.configurations) {
        if (toRemove.boxes <= 0) throw new BadRequestException('出库箱数不能为零或负数');
        const found = sourceConfigs.find(c => c.unitsPerBox === toRemove.unitsPerBox);
        const available = found?.boxes ?? 0;
        if (toRemove.boxes > available) {
          throw new BadRequestException(
            `库存不足：${toRemove.unitsPerBox}件/箱 当前 ${available} 箱，出库 ${toRemove.boxes} 箱`,
          );
        }
      }
      record.configurations = sourceConfigs
        .map(c => {
          const toRemove = dto.configurations!.find(r => r.unitsPerBox === c.unitsPerBox);
          return { boxes: c.boxes - (toRemove?.boxes ?? 0), unitsPerBox: c.unitsPerBox };
        })
        .filter(c => c.boxes > 0);
      record.markModified('configurations');
      reducedQty = dto.configurations.reduce((s, c) => s + c.boxes * c.unitsPerBox, 0);
      const parts = dto.configurations.map(c => `${c.boxes}箱×${c.unitsPerBox}件/箱`).join('+');
      outDeltaStr = `-${parts}=-${reducedQty}件`;

    } else if (dto.unconfiguredCartons !== undefined && dto.unconfiguredCartons > 0) {
      // ── cartons-only: deduct from unconfiguredCartons (does NOT affect quantity) ──
      const available = record.unconfiguredCartons ?? 0;
      if (dto.unconfiguredCartons > available) {
        throw new BadRequestException(
          `无箱规库存不足：当前 ${available} 箱，出库 ${dto.unconfiguredCartons} 箱`,
        );
      }
      record.unconfiguredCartons = available - dto.unconfiguredCartons;
      reducedQty = 0; // unconfiguredCartons never contribute to quantity
      outDeltaStr = `-${dto.unconfiguredCartons}箱（无箱规）`;

    } else if (dto.quantity !== undefined && dto.quantity > 0) {
      // ── by-qty: deduct from loosePcs only. Never cross-deduct from configurations.
      const available = record.loosePcs ?? 0;
      if (dto.quantity > available) {
        throw new BadRequestException(
          `散件库存不足：当前 ${available} 件，出库 ${dto.quantity} 件`,
        );
      }
      record.loosePcs = available - dto.quantity;
      reducedQty = dto.quantity;
      outDeltaStr = `-${dto.quantity}件`;

    } else {
      throw new BadRequestException('出库数量不能为零');
    }

    // Recompute derived summary fields
    record.quantity = this.computeQtyFromStructure(record);
    record.boxes    = this.computeTotalCartons(record);
    const cfgs = record.configurations ?? [];
    record.unitsPerBox = cfgs.length === 1 ? cfgs[0].unitsPerBox : 0;
    // boxesOnlyMode stays true only when record has only unconfiguredCartons
    if ((record.loosePcs ?? 0) > 0 || cfgs.length > 0) record.boxesOnlyMode = false;

    await record.save();

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'inventory',
      businessAction: '出库',
      description: `出库: ${sku.sku} @ ${location.code} ${outDeltaStr}`,
      details: {
        skuCode: sku.sku,
        locationCode: location.code,
        reducedQty,
        remainingQty: record.quantity,
        configurations: dto.configurations,
        ...(dto.unconfiguredCartons ? { unconfiguredCartons: dto.unconfiguredCartons } : {}),
      },
    });

    await this.txModel.create({
      skuCode: sku.sku,
      locationId: new Types.ObjectId(dto.locationId),
      locationCode: location.code,
      type: 'OUT',
      quantity: reducedQty,
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
    loosePcs?: number;   // pcs not in any carton spec (mixed mode)
    adjustMode?: 'qty' | 'configs' | 'boxes_only' | 'mixed';
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

    const configs = dto.configurations ?? [];
    const loose = dto.loosePcs ?? 0;

    if (configs.length > 0 || loose > 0) {
      // mixed mode: carton specs + optional loose pcs
      record.configurations = configs;
      record.markModified('configurations');
      record.boxes = configs.reduce((s, c) => s + c.boxes, 0);
      record.quantity = configs.reduce((s, c) => s + c.boxes * c.unitsPerBox, 0) + loose;
      record.boxesOnlyMode = false;
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

    const modeLabel = dto.adjustMode === 'mixed' ? '结构调整'
      : dto.adjustMode === 'configs' ? '箱规调整'
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
