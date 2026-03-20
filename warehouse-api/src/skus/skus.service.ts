import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
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

  async findAll(search?: string) {
    const filter: any = {};
    if (search) {
      filter.$or = [
        { sku: { $regex: search, $options: 'i' } },
        { name: { $regex: search, $options: 'i' } },
        { barcode: { $regex: search, $options: 'i' } },
      ];
    }
    const skus = await this.skuModel.find(filter).lean();

    const inventories = await this.inventoryModel
      .find({ skuId: { $in: skus.map((s) => s._id) } })
      .populate('locationId', 'code')
      .lean();

    const invMap = new Map<string, { locationId: string; locationCode: string; qty: number }[]>();
    for (const inv of inventories) {
      const key = inv.skuId.toString();
      if (!invMap.has(key)) invMap.set(key, []);
      const loc = inv.locationId as any;
      invMap.get(key)!.push({ locationId: loc?._id?.toString() ?? '', locationCode: loc?.code ?? '?', qty: inv.quantity });
    }

    return skus.map((s) => {
      const locs = invMap.get((s._id as any).toString()) ?? [];
      return {
        ...s,
        locations: locs,
        totalQty: locs.reduce((sum, l) => sum + l.qty, 0),
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

    const totalQty = inventory.reduce((sum, r) => sum + r.quantity, 0);
    const totalPcs = sku.cartonQty ? totalQty * sku.cartonQty : null;

    return { ...sku, inventory, totalQty, totalPcs };
  }

  async create(dto: CreateSkuDto, user: any) {
    const exists = await this.skuModel.findOne({ sku: dto.sku.toUpperCase() });
    if (exists) throw new ConflictException('SKU 编号已存在');

    const sku = await this.skuModel.create({ ...dto, sku: dto.sku.toUpperCase() });

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
    const sku = await this.skuModel.findByIdAndUpdate(id, dto, { new: true });
    if (!sku) throw new NotFoundException('SKU 不存在');

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'sku',
      description: `编辑 SKU: ${sku.sku}`,
    });

    return sku;
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
