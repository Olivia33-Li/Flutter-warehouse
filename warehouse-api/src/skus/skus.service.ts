import { Injectable, NotFoundException, ConflictException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Sku, SkuDocument } from '../schemas/sku.schema';
import { Inventory, InventoryDocument } from '../schemas/inventory.schema';
import { HistoryService } from '../history/history.service';
import { CreateSkuDto, UpdateSkuDto } from './dto/sku.dto';

@Injectable()
export class SkusService {
  constructor(
    @InjectModel(Sku.name) private skuModel: Model<SkuDocument>,
    @InjectModel(Inventory.name) private inventoryModel: Model<InventoryDocument>,
    private historyService: HistoryService,
  ) {}

  // statusFilter: 'active' (default) | 'archived' | 'all'
  async findAll(search?: string, statusFilter: 'active' | 'archived' | 'all' = 'active') {
    const filter: any = {};
    if (statusFilter === 'active') {
      // backwards-compat: treat null/missing status as active
      filter.$or = [{ status: 'active' }, { status: { $exists: false } }, { status: null }];
    } else if (statusFilter === 'archived') {
      filter.status = 'archived';
    }
    // 'all' → no status filter

    let skus = await this.skuModel.find(filter).lean();

    if (search && search.trim()) {
      const norm = (s: string) => s.toLowerCase().replace(/[-_/\s"'.]/g, '');
      const q = norm(search.trim());
      skus = skus.filter((s) => {
        return [s.sku, s.name ?? '', s.barcode ?? ''].some((f) => norm(f).includes(q));
      });
    }

    const inventories = await this.inventoryModel
      .find({ skuId: { $in: skus.map((s) => s._id) } })
      .populate('locationId', 'code')
      .lean();

    const invMap = new Map<string, { locationId: string; locationCode: string; totalQty: number; boxes: number; unitsPerBox: number; boxesOnly: boolean }[]>();
    for (const inv of inventories) {
      const key = inv.skuId.toString();
      if (!invMap.has(key)) invMap.set(key, []);
      const loc = inv.locationId as any;
      const boxes = inv.boxes ?? 0;
      const unitsPerBox = inv.unitsPerBox ?? 1;
      const totalQty = (inv.quantity ?? 0) > 0
        ? inv.quantity
        : boxes * unitsPerBox;
      invMap.get(key)!.push({
        locationId: loc?._id?.toString() ?? '',
        locationCode: loc?.code ?? '?',
        totalQty,
        boxes,
        unitsPerBox,
        boxesOnly: !!(inv as any).boxesOnlyMode,
      });
    }

    return skus.map((s) => {
      const locs = invMap.get((s._id as any).toString()) ?? [];
      return {
        ...s,
        // normalise missing status to 'active' in response
        status: s.status ?? 'active',
        locations: locs,
        totalQty: locs.reduce((sum, l) => sum + l.totalQty, 0),
      };
    });
  }

  async findOne(id: string) {
    const sku = await this.skuModel.findById(id).lean();
    if (!sku) throw new NotFoundException('SKU 不存在');

    const inventory = await this.inventoryModel
      .find({ skuId: new Types.ObjectId(id) })
      .populate('locationId', 'code description')
      .lean();

    const formatted = inventory.map((r) => {
      const loc = r.locationId as any;
      const isBoxesOnly = !!(r as any).boxesOnlyMode;
      const boxes = (r.boxes ?? 0) > 0 ? r.boxes : (r.quantity ?? 0);
      const unitsPerBox = r.unitsPerBox ?? 1;
      return {
        ...r,
        skuCode: r.skuCode || sku.sku,
        locationId: loc,
        boxes,
        unitsPerBox,
        quantity: isBoxesOnly ? 0 : (r.quantity ?? boxes * unitsPerBox),
      };
    });

    const totalQty = formatted.reduce((sum, r) => (r as any).boxesOnlyMode ? sum : sum + (r.quantity ?? 0), 0);
    const totalBoxes = formatted.reduce((sum, r) => sum + (r.boxes ?? 0), 0);
    const totalPcs = sku.cartonQty ? totalQty * sku.cartonQty : null;

    return { ...sku, status: sku.status ?? 'active', inventory: formatted, totalQty, totalBoxes, totalPcs };
  }

  async create(dto: CreateSkuDto, user: any) {
    const exists = await this.skuModel.findOne({ sku: dto.sku.toUpperCase() });
    if (exists) throw new ConflictException('SKU 编号已存在');

    // New SKUs always start as active — status never comes from the DTO
    const sku = await this.skuModel.create({
      ...dto,
      sku: dto.sku.toUpperCase(),
      status: 'active',
    });

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'add',
      entity: 'sku',
      description: `新增 SKU: ${sku.sku}`,
    });

    return sku;
  }

  async update(id: string, dto: UpdateSkuDto, user: any) {
    const sku = await this.skuModel.findById(id);
    if (!sku) throw new NotFoundException('SKU 不存在');

    const barcodeChanged = dto.barcode !== undefined && dto.barcode !== sku.barcode;

    if (dto.name !== undefined) sku.name = dto.name;
    if (dto.cartonQty !== undefined) sku.cartonQty = dto.cartonQty;
    if (dto.barcode !== undefined) sku.barcode = dto.barcode;

    if (barcodeChanged) {
      sku.barcodeHistory.push({
        barcode: dto.barcode!,
        changedBy: user.name,
        source: 'manual',
        changedAt: new Date(),
      });
    }

    await sku.save();

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'sku',
      description: barcodeChanged
        ? `编辑 SKU: ${sku.sku}（条码已更新）`
        : `编辑 SKU: ${sku.sku}`,
    });

    return sku;
  }

  async getBarcodeHistory(id: string) {
    const sku = await this.skuModel.findById(id).lean();
    if (!sku) throw new NotFoundException('SKU 不存在');
    return {
      skuCode: sku.sku,
      currentBarcode: sku.barcode ?? null,
      history: (sku.barcodeHistory ?? []).slice().reverse(),
    };
  }

  async archive(id: string, user: any) {
    const sku = await this.skuModel.findById(id);
    if (!sku) throw new NotFoundException('SKU 不存在');
    if ((sku.status ?? 'active') === 'archived') {
      throw new BadRequestException('SKU 已是归档状态');
    }

    // Check if there is remaining inventory
    const invCount = await this.inventoryModel.countDocuments({ skuId: new Types.ObjectId(id) });
    const hasStock = invCount > 0;

    sku.status = 'archived';
    await sku.save();

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'sku',
      description: `归档 SKU: ${sku.sku}${hasStock ? '（仍有库存记录）' : ''}`,
    });

    return { message: `SKU ${sku.sku} 已归档`, hasStock };
  }

  async restore(id: string, user: any) {
    const sku = await this.skuModel.findById(id);
    if (!sku) throw new NotFoundException('SKU 不存在');
    if ((sku.status ?? 'active') !== 'archived') {
      throw new BadRequestException('SKU 不是归档状态');
    }

    sku.status = 'active';
    await sku.save();

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'sku',
      description: `恢复 SKU: ${sku.sku}`,
    });

    return { message: `SKU ${sku.sku} 已恢复为在用` };
  }

  async remove(id: string, user: any) {
    const sku = await this.skuModel.findById(id);
    if (!sku) throw new NotFoundException('SKU 不存在');

    await this.inventoryModel.deleteMany({ skuId: new Types.ObjectId(id) });
    await this.skuModel.findByIdAndDelete(id);

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'delete',
      entity: 'sku',
      description: `删除 SKU: ${sku.sku}`,
    });

    return { message: 'SKU 已删除' };
  }
}
