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
    // Normalize: strip common separators, lowercase for matching
    const norm = (s: string) => s.toLowerCase().replace(/[-_/\s"'.]/g, '');

    let locations = await this.locationModel.find({}).lean();

    // Pull lightweight inventory stats for all locations at once
    // Exclude tombstone records left by merge/split operations — they are zero-qty and must not affect counts.
    const allInv = await this.inventoryModel
      .find({ stockStatus: { $nin: ['completed_merge', 'completed_split'] } })
      .populate('skuId', 'sku name')
      .lean();

    type InvStat = {
      skuCount: number;
      totalQty: number;
      totalBoxes: number;
      skuCodes: string[];
      skuNames: string[];
    };
    const statMap = new Map<string, InvStat>();
    for (const inv of allInv) {
      const locKey = inv.locationId.toString();
      if (!statMap.has(locKey)) {
        statMap.set(locKey, { skuCount: 0, totalQty: 0, totalBoxes: 0, skuCodes: [], skuNames: [] });
      }
      const stat = statMap.get(locKey)!;
      // Only count SKUs that actually have stock (boxes > 0, quantity > 0, or quantityUnknown)
      if ((inv.boxes ?? 0) > 0 || (inv.quantity ?? 0) > 0 || (inv as any).quantityUnknown) {
        stat.skuCount++;
      }
      stat.totalBoxes += inv.boxes ?? 0;
      if (!(inv as any).boxesOnlyMode) stat.totalQty += inv.quantity ?? 0;
      const sku = inv.skuId as any;
      if (sku?.sku) stat.skuCodes.push(sku.sku);
      if (sku?.name) stat.skuNames.push(sku.name);
    }

    // Filter with fuzzy matching across code, description, skuCodes, skuNames
    if (search && search.trim()) {
      const q = norm(search.trim());
      locations = locations.filter((loc) => {
        const stat = statMap.get((loc._id as any).toString());
        const fields = [
          loc.code,
          loc.description ?? '',
          ...(stat?.skuCodes ?? []),
          ...(stat?.skuNames ?? []),
        ];
        return fields.some((f) => norm(f).includes(q));
      });
    }

    return locations.map((loc) => {
      const stat = statMap.get((loc._id as any).toString()) ?? {
        skuCount: 0, totalQty: 0, totalBoxes: 0, skuCodes: [], skuNames: [],
      };
      return {
        ...loc,
        skuCount: stat.skuCount,
        totalQty: stat.totalQty,
        totalBoxes: stat.totalBoxes,
      };
    });
  }

  async findOne(id: string) {
    const location = await this.locationModel.findById(id).lean();
    if (!location) throw new NotFoundException('位置不存在');

    const inventory = await this.inventoryModel
      .find({ locationId: new Types.ObjectId(id), stockStatus: { $nin: ['completed_merge', 'completed_split'] } })
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

    // Populate SKU name so it can be stored in the audit log detail
    const sourceInv = await this.inventoryModel
      .find(filter)
      .populate('skuId', 'sku name')
      .lean();

    const conflictResolution = dto.conflictResolution ?? 'skip';
    const batchId = new Types.ObjectId().toHexString();

    type ItemDetail = {
      skuCode: string;
      skuName?: string;
      qty: number;
      boxes: number;
      unitsPerBox: number;
      configurations: { boxes: number; unitsPerBox: number }[];
    };

    // primary = moved (transfer) or copied (copy) — no pre-existing target record
    const primaryItems: ItemDetail[] = [];
    const mergedItems: ItemDetail[] = [];
    const overwrittenItems: ItemDetail[] = [];
    const skippedItems: ItemDetail[] = [];

    for (const inv of sourceInv) {
      const existing = await this.inventoryModel.findOne({
        skuId: inv.skuId,
        locationId: new Types.ObjectId(dto.targetLocationId),
      });

      const skuRef = inv.skuId as any;
      const item: ItemDetail = {
        skuCode: inv.skuCode,
        skuName: skuRef?.name ?? undefined,
        qty: inv.quantity ?? 0,
        boxes: inv.boxes ?? 0,
        unitsPerBox: inv.unitsPerBox ?? 1,
        configurations: (inv.configurations ?? []) as { boxes: number; unitsPerBox: number }[],
      };

      if (existing) {
        if (conflictResolution === 'overwrite') {
          existing.boxes = inv.boxes;
          existing.unitsPerBox = inv.unitsPerBox;
          existing.configurations = inv.configurations;
          existing.quantity = inv.quantity;
          existing.stockStatus = inv.stockStatus;
          await existing.save();
          overwrittenItems.push(item);
        } else if (conflictResolution === 'merge') {
          existing.boxes = (existing.boxes ?? 0) + (inv.boxes ?? 0);
          existing.quantity = (existing.quantity ?? 0) + (inv.quantity ?? 0);
          await existing.save();
          mergedItems.push(item);
        } else {
          skippedItems.push(item);
          continue;
        }
      } else {
        await this.inventoryModel.create({
          ...inv,
          _id: undefined,
          locationId: new Types.ObjectId(dto.targetLocationId),
        });
        primaryItems.push(item);
      }

      if (deleteSource) {
        await this.inventoryModel.findByIdAndDelete(inv._id);
      }
    }

    const changedItems = [...primaryItems, ...mergedItems, ...overwrittenItems];
    const total = changedItems.length;

    // Format per-item summary for description (first 3 SKUs)
    const formatItem = (i: ItemDetail): string => {
      if (i.configurations.length > 0) {
        const cfgStr = i.configurations.map(c => `${c.boxes}箱×${c.unitsPerBox}件`).join('+');
        return `${i.skuCode}(${cfgStr})`;
      }
      if (i.boxes > 0 && i.unitsPerBox > 1) return `${i.skuCode}(${i.boxes}箱·${i.qty}件)`;
      return `${i.skuCode}(${i.qty || i.boxes}件)`;
    };
    const preview = changedItems.slice(0, 3).map(formatItem).join('、');
    const routePrefix = `[${source.code}→${target.code}]`;
    const totalHint = total > 3 ? `等${total}种` : `共${total}种`;
    const itemDesc = total > 0 ? `${preview}${total > 3 ? '…' : ''}${total > 3 ? totalHint : ''}` : '无实际变更';

    const sourceAction = deleteSource ? '批量转移' : '批量复制';
    const targetAction = deleteSource ? '批量转入' : '批量复制进入';

    const commonDetails = {
      batchId,
      sourceCode: source.code,
      targetCode: target.code,
      total,
      skippedCount: skippedItems.length,
      overwrittenDetails: overwrittenItems,
      ...(deleteSource
        ? { movedDetails: primaryItems, mergedDetails: mergedItems }
        : { copiedDetails: primaryItems, stackedDetails: mergedItems }),
    };

    // ── Source location record ──
    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'inventory',
      businessAction: sourceAction,
      description: `${routePrefix} ${sourceAction}：${itemDesc}`,
      locationCode: source.code,
      details: { ...commonDetails, role: 'source' },
    });

    // ── Target location record ──
    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'inventory',
      businessAction: targetAction,
      description: `${routePrefix} ${targetAction}：${itemDesc}`,
      locationCode: target.code,
      details: { ...commonDetails, role: 'target' },
    });

    return deleteSource
      ? {
          moved: primaryItems.map(i => i.skuCode),
          merged: mergedItems.map(i => i.skuCode),
          overwritten: overwrittenItems.map(i => i.skuCode),
          skipped: skippedItems.map(i => i.skuCode),
        }
      : {
          copied: primaryItems.map(i => i.skuCode),
          stacked: mergedItems.map(i => i.skuCode),
          overwritten: overwrittenItems.map(i => i.skuCode),
          skipped: skippedItems.map(i => i.skuCode),
        };
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
