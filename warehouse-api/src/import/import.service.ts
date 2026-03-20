import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { parse } from 'csv-parse/sync';
import { Sku, SkuDocument } from '../schemas/sku.schema';
import { Location, LocationDocument } from '../schemas/location.schema';
import { Inventory, InventoryDocument } from '../schemas/inventory.schema';
import { HistoryService } from '../history/history.service';

@Injectable()
export class ImportService {
  constructor(
    @InjectModel(Sku.name) private skuModel: Model<SkuDocument>,
    @InjectModel(Location.name) private locationModel: Model<LocationDocument>,
    @InjectModel(Inventory.name) private inventoryModel: Model<InventoryDocument>,
    private historyService: HistoryService,
  ) {}

  async importCsv(buffer: Buffer, user: any) {
    let records: any[];
    try {
      records = parse(buffer, {
        columns: true,
        skip_empty_lines: true,
        trim: true,
      });
    } catch {
      throw new BadRequestException('CSV 文件解析失败，请检查格式');
    }

    if (records.length === 0) throw new BadRequestException('CSV 文件为空');

    // 智能列名映射
    const firstRow = records[0];
    const cols = Object.keys(firstRow).map((k) => k.toLowerCase());
    const getCol = (keys: string[]) => {
      for (const k of keys) {
        const match = Object.keys(firstRow).find((c) => c.toLowerCase().includes(k));
        if (match) return match;
      }
      return null;
    };

    const skuCol = getCol(['sku', 'item', 'code', 'product']);
    const locationCol = getCol(['location', 'loc', 'position', 'bin', 'warehouse']);
    const qtyCol = getCol(['qty', 'quantity', 'carton', 'box', 'count']);
    const nameCol = getCol(['name', 'description', 'desc', 'product_name']);
    const barcodeCol = getCol(['barcode', 'bar', 'upc', 'ean']);
    const cartonQtyCol = getCol(['carton_qty', 'cartonqty', 'pcs', 'pieces', 'unit']);

    if (!skuCol) throw new BadRequestException('找不到 SKU 列，请确保 CSV 包含 sku/item/code 列');
    if (!locationCol) throw new BadRequestException('找不到位置列，请确保 CSV 包含 location/loc 列');
    if (!qtyCol) throw new BadRequestException('找不到数量列，请确保 CSV 包含 qty/quantity 列');

    let created = 0, updated = 0, skipped = 0;

    for (const row of records) {
      const skuCode = row[skuCol]?.toString().toUpperCase().trim();
      const locationCode = row[locationCol]?.toString().toUpperCase().trim();
      const qty = parseInt(row[qtyCol]) || 0;

      if (!skuCode || !locationCode) { skipped++; continue; }

      // 创建或获取 SKU
      let sku = await this.skuModel.findOne({ sku: skuCode });
      if (!sku) {
        sku = await this.skuModel.create({
          sku: skuCode,
          name: nameCol ? row[nameCol] : undefined,
          barcode: barcodeCol ? row[barcodeCol] : undefined,
          cartonQty: cartonQtyCol ? parseInt(row[cartonQtyCol]) || undefined : undefined,
        });
      }

      // 创建或获取位置
      let location = await this.locationModel.findOne({ code: locationCode });
      if (!location) {
        location = await this.locationModel.create({ code: locationCode });
      }

      // 更新库存（累加）
      const existing = await this.inventoryModel.findOne({
        skuId: sku._id,
        locationId: location._id,
      });

      if (existing) {
        existing.quantity += qty;
        await existing.save();
        updated++;
      } else {
        await this.inventoryModel.create({
          skuId: sku._id,
          locationId: location._id,
          quantity: qty,
        });
        created++;
      }
    }

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'import',
      entity: 'inventory',
      description: `CSV 导入: 新增 ${created} 条，更新 ${updated} 条，跳过 ${skipped} 条，共 ${records.length} 行`,
    });

    return { total: records.length, created, updated, skipped };
  }
}
