import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as ExcelJS from 'exceljs';
import { Sku, SkuDocument } from '../schemas/sku.schema';
import { Location, LocationDocument } from '../schemas/location.schema';
import { Inventory, InventoryDocument } from '../schemas/inventory.schema';
import { ChangeRecord, ChangeRecordDocument } from '../schemas/change-record.schema';

@Injectable()
export class ExportService {
  constructor(
    @InjectModel(Sku.name) private skuModel: Model<SkuDocument>,
    @InjectModel(Location.name) private locationModel: Model<LocationDocument>,
    @InjectModel(Inventory.name) private inventoryModel: Model<InventoryDocument>,
    @InjectModel(ChangeRecord.name) private changeRecordModel: Model<ChangeRecordDocument>,
  ) {}

  async exportAllToExcel(): Promise<Buffer> {
    console.log('[ExportService] exportAllToExcel called');

    const [skus, locations, inventories, changeRecords] = await Promise.all([
      this.skuModel.find().sort({ sku: 1 }).lean(),
      this.locationModel.find().sort({ code: 1 }).lean(),
      this.inventoryModel.find().sort({ skuCode: 1 }).lean(),
      this.changeRecordModel.find().sort({ createdAt: -1 }).limit(2000).lean(),
    ]);

    console.log(
      `[ExportService] skus=${skus.length}, locations=${locations.length}, ` +
      `inventories=${inventories.length}, changeRecords=${changeRecords.length}`,
    );

    // Build locationId → code lookup
    const locationMap = new Map(locations.map((l) => [l._id.toString(), l.code]));

    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'WarehouseSystem';
    workbook.created = new Date();

    // ── Sheet 1: SKU 主档 ──────────────────────────────────────────────────
    const skuSheet = workbook.addWorksheet('SKU主档');
    skuSheet.columns = [
      { header: 'SKU编码', key: 'sku', width: 22 },
      { header: '名称', key: 'name', width: 32 },
      { header: '条形码', key: 'barcode', width: 22 },
      { header: '默认箱规(件/箱)', key: 'cartonQty', width: 18 },
      { header: '创建时间', key: 'createdAt', width: 22 },
    ];
    this._styleHeader(skuSheet);
    for (const s of skus) {
      skuSheet.addRow({
        sku: s.sku,
        name: s.name ?? '',
        barcode: s.barcode ?? '',
        cartonQty: s.cartonQty ?? '',
        createdAt: this._fmt(s['createdAt']),
      });
    }

    // ── Sheet 2: 库位主档 ──────────────────────────────────────────────────
    const locationSheet = workbook.addWorksheet('库位主档');
    locationSheet.columns = [
      { header: '库位编码', key: 'code', width: 20 },
      { header: '描述', key: 'description', width: 32 },
      { header: '最后盘点时间', key: 'checkedAt', width: 22 },
      { header: '创建时间', key: 'createdAt', width: 22 },
    ];
    this._styleHeader(locationSheet);
    for (const l of locations) {
      locationSheet.addRow({
        code: l.code,
        description: l.description ?? '',
        checkedAt: this._fmt(l.checkedAt),
        createdAt: this._fmt(l['createdAt']),
      });
    }

    // ── Sheet 3: 库存明细 ──────────────────────────────────────────────────
    const invSheet = workbook.addWorksheet('库存明细');
    invSheet.columns = [
      { header: 'SKU编码', key: 'skuCode', width: 22 },
      { header: '库位', key: 'location', width: 16 },
      { header: '箱数', key: 'boxes', width: 10 },
      { header: '箱规(件/箱)', key: 'unitsPerBox', width: 14 },
      { header: '总件数', key: 'quantity', width: 12 },
      { header: '仅箱模式', key: 'boxesOnlyMode', width: 12 },
      { header: '库存状态', key: 'stockStatus', width: 14 },
      { header: '备注', key: 'note', width: 30 },
      { header: '更新时间', key: 'updatedAt', width: 22 },
    ];
    this._styleHeader(invSheet);
    for (const inv of inventories) {
      const isBoxesOnly = inv.boxesOnlyMode;
      invSheet.addRow({
        skuCode: inv.skuCode,
        location: locationMap.get(inv.locationId.toString()) ?? inv.locationId.toString(),
        boxes: inv.boxes,
        unitsPerBox: isBoxesOnly ? '—' : inv.unitsPerBox,
        quantity: isBoxesOnly ? '—' : inv.quantity,
        boxesOnlyMode: isBoxesOnly ? '是' : '否',
        stockStatus: this._statusLabel(inv.stockStatus),
        note: inv.note ?? '',
        updatedAt: this._fmt(inv['updatedAt']),
      });
    }

    // ── Sheet 4: 操作流水 ──────────────────────────────────────────────────
    const historySheet = workbook.addWorksheet('操作流水');
    historySheet.columns = [
      { header: '时间', key: 'createdAt', width: 22 },
      { header: '操作人', key: 'userName', width: 16 },
      { header: '操作类型', key: 'action', width: 14 },
      { header: '对象', key: 'entity', width: 14 },
      { header: '描述', key: 'description', width: 60 },
    ];
    this._styleHeader(historySheet);
    for (const r of changeRecords) {
      historySheet.addRow({
        createdAt: this._fmt(r['createdAt']),
        userName: r.userName,
        action: r.action,
        entity: r.entity,
        description: r.description,
      });
    }

    const buffer = await workbook.xlsx.writeBuffer();
    console.log(`[ExportService] Excel ready, bytes=${buffer.byteLength}`);
    return Buffer.from(buffer);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  private _styleHeader(sheet: ExcelJS.Worksheet) {
    const row = sheet.getRow(1);
    row.font = { bold: true, color: { argb: 'FF1F4E79' } };
    row.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFD9EAD3' } };
    row.alignment = { vertical: 'middle', horizontal: 'center' };
    row.height = 22;
  }

  private _fmt(date: any): string {
    if (!date) return '';
    try {
      return new Date(date).toLocaleString('zh-CN', { hour12: false });
    } catch {
      return '';
    }
  }

  private _statusLabel(status: string): string {
    switch (status) {
      case 'confirmed': return '已确认';
      case 'pending_count': return '待清点';
      case 'temporary': return '临时';
      default: return status ?? '';
    }
  }
}
