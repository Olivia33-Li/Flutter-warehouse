import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { parse } from 'csv-parse/sync';
import * as ExcelJS from 'exceljs';
import { Sku, SkuDocument } from '../schemas/sku.schema';
import { Location, LocationDocument } from '../schemas/location.schema';
import { Inventory, InventoryDocument } from '../schemas/inventory.schema';
import { ImportLog, ImportLogDocument } from '../schemas/import-log.schema';
import { HistoryService } from '../history/history.service';

@Injectable()
export class ImportService {
  constructor(
    @InjectModel(Sku.name) private skuModel: Model<SkuDocument>,
    @InjectModel(Location.name) private locationModel: Model<LocationDocument>,
    @InjectModel(Inventory.name) private inventoryModel: Model<InventoryDocument>,
    @InjectModel(ImportLog.name) private importLogModel: Model<ImportLogDocument>,
    private historyService: HistoryService,
  ) {}

  // ─── Validate (dry run, no DB writes) ────────────────────────────────────────

  async validateSkus(buffer: Buffer, filename: string) {
    const records = await this._parseFile(buffer, filename);
    const rows: any[] = [];
    let willCreate = 0, willUpdate = 0, willSkip = 0, errorCount = 0;

    for (let i = 0; i < records.length; i++) {
      const row = records[i];
      const rowNum = i + 2;
      const skuCode = this._str(row['sku_code'] || row['sku'] || row['code']).toUpperCase();

      if (!skuCode) {
        rows.push({ row: rowNum, action: 'skip', summary: '缺少 sku_code，已跳过', error: null });
        willSkip++;
        continue;
      }

      const existing = await this.skuModel.findOne({ sku: skuCode });
      if (existing) {
        rows.push({ row: rowNum, action: 'update', summary: `更新 SKU: ${skuCode}`, error: null });
        willUpdate++;
      } else {
        rows.push({ row: rowNum, action: 'create', summary: `新建 SKU: ${skuCode}`, error: null });
        willCreate++;
      }
    }

    return { total: records.length, willCreate, willUpdate, willSkip, errorCount, rows };
  }

  async validateLocations(buffer: Buffer, filename: string) {
    const records = await this._parseFile(buffer, filename);
    const rows: any[] = [];
    let willCreate = 0, willUpdate = 0, willSkip = 0, errorCount = 0;

    for (let i = 0; i < records.length; i++) {
      const row = records[i];
      const rowNum = i + 2;
      const code = this._str(row['location_code'] || row['location'] || row['code']).toUpperCase();

      if (!code) {
        rows.push({ row: rowNum, action: 'skip', summary: '缺少 location_code，已跳过', error: null });
        willSkip++;
        continue;
      }

      const existing = await this.locationModel.findOne({ code });
      if (existing) {
        rows.push({ row: rowNum, action: 'update', summary: `更新库位: ${code}`, error: null });
        willUpdate++;
      } else {
        rows.push({ row: rowNum, action: 'create', summary: `新建库位: ${code}`, error: null });
        willCreate++;
      }
    }

    return { total: records.length, willCreate, willUpdate, willSkip, errorCount, rows };
  }

  async validateInventory(buffer: Buffer, filename: string) {
    const records = await this._parseFile(buffer, filename);
    const rows: any[] = [];
    let willCreate = 0, willUpdate = 0, willSkip = 0, errorCount = 0;

    // Track seen SKU+location combos to detect multi-row merges
    const seenKeys = new Map<string, number>(); // key → row index in rows[]

    for (let i = 0; i < records.length; i++) {
      const row = records[i];
      const rowNum = i + 2;
      const skuCode = this._str(row['sku_code'] || row['sku']).toUpperCase();
      const locationCode = this._str(row['location_code'] || row['location']).toUpperCase();

      if (!skuCode || !locationCode) {
        rows.push({ row: rowNum, action: 'skip', summary: '缺少 sku_code 或 location_code，已跳过', error: null });
        willSkip++;
        continue;
      }

      const sku = await this.skuModel.findOne({ sku: skuCode });
      if (!sku) {
        const err = `SKU ${skuCode} 不存在`;
        rows.push({ row: rowNum, action: 'skip', summary: err, error: err });
        willSkip++;
        errorCount++;
        continue;
      }

      const location = await this.locationModel.findOne({ code: locationCode });
      if (!location) {
        const err = `库位 ${locationCode} 不存在`;
        rows.push({ row: rowNum, action: 'skip', summary: err, error: err });
        willSkip++;
        errorCount++;
        continue;
      }

      const key = `${skuCode}||${locationCode}`;
      if (seenKeys.has(key)) {
        // This row will be merged into the same inventory record — mark as merge
        const prevIdx = seenKeys.get(key)!;
        rows[prevIdx].summary += `（含第${rowNum}行，多箱规合并）`;
        rows.push({ row: rowNum, action: 'merge', summary: `合并到 ${skuCode} @ ${locationCode}`, error: null });
        continue;
      }

      const existing = await this.inventoryModel.findOne({ skuId: sku._id, locationId: location._id });
      const action = existing ? 'update' : 'create';
      const summary = existing ? `更新库存: ${skuCode} @ ${locationCode}` : `新建库存: ${skuCode} @ ${locationCode}`;
      const idx = rows.length;
      rows.push({ row: rowNum, action, summary, error: null });
      seenKeys.set(key, idx);
      if (existing) willUpdate++; else willCreate++;
    }

    return { total: records.length, willCreate, willUpdate, willSkip, errorCount, rows };
  }

  // ─── Import (write to DB) ─────────────────────────────────────────────────────

  async importSkus(buffer: Buffer, filename: string, user: any) {
    const records = await this._parseFile(buffer, filename);
    let created = 0, updated = 0, skipped = 0;
    const errors: { row: number; message: string }[] = [];

    for (let i = 0; i < records.length; i++) {
      const row = records[i];
      const skuCode = this._str(row['sku_code'] || row['sku'] || row['code']).toUpperCase();

      if (!skuCode) { skipped++; continue; }

      const name = this._str(row['name']) || undefined;
      const barcode = this._str(row['barcode']) || undefined;
      const cartonQty = parseInt(row['default_carton_qty'] || row['carton_qty'] || '') || undefined;

      const existing = await this.skuModel.findOne({ sku: skuCode });
      if (existing) {
        if (name) existing.name = name;
        if (barcode) existing.barcode = barcode;
        if (cartonQty) existing.cartonQty = cartonQty;
        await existing.save();
        updated++;
      } else {
        await this.skuModel.create({ sku: skuCode, name, barcode, cartonQty });
        created++;
      }
    }

    await this.importLogModel.create({
      userId: user._id,
      userName: user.name,
      importType: 'skus',
      filename,
      total: records.length,
      created,
      updated,
      skipped,
      importErrors: errors,
    });

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'import',
      entity: 'sku',
      description: `SKU 导入 [${filename}]: 新增 ${created}，更新 ${updated}，跳过 ${skipped}`,
    });

    return { total: records.length, created, updated, skipped, errors };
  }

  async importLocations(buffer: Buffer, filename: string, user: any) {
    const records = await this._parseFile(buffer, filename);
    let created = 0, updated = 0, skipped = 0;
    const errors: { row: number; message: string }[] = [];

    for (let i = 0; i < records.length; i++) {
      const row = records[i];
      const code = this._str(row['location_code'] || row['location'] || row['code']).toUpperCase();

      if (!code) { skipped++; continue; }

      const description = this._str(row['description']) || undefined;

      const existing = await this.locationModel.findOne({ code });
      if (existing) {
        if (description) existing.description = description;
        await existing.save();
        updated++;
      } else {
        await this.locationModel.create({ code, description });
        created++;
      }
    }

    await this.importLogModel.create({
      userId: user._id,
      userName: user.name,
      importType: 'locations',
      filename,
      total: records.length,
      created,
      updated,
      skipped,
      importErrors: errors,
    });

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'import',
      entity: 'location',
      description: `库位导入 [${filename}]: 新增 ${created}，更新 ${updated}，跳过 ${skipped}`,
    });

    return { total: records.length, created, updated, skipped, errors };
  }

  async importInventory(buffer: Buffer, filename: string, user: any) {
    const records = await this._parseFile(buffer, filename);
    let created = 0, updated = 0, skipped = 0;
    const errors: { row: number; message: string }[] = [];

    // ── Step 1: parse every row and group by skuCode+locationCode ──────────
    type ParsedRow = {
      rowNum: number;
      skuCode: string;
      locationCode: string;
      calcBoxes: number;
      calcUnits: number;
      quantity: number;
      isPending: boolean;
      boxesOnly: boolean;
    };

    const groupMap = new Map<string, ParsedRow[]>();

    for (let i = 0; i < records.length; i++) {
      const row = records[i];
      const rowNum = i + 2;
      const skuCode = this._str(row['sku_code'] || row['sku']).toUpperCase();
      const locationCode = this._str(row['location_code'] || row['location']).toUpperCase();

      if (!skuCode || !locationCode) { skipped++; continue; }

      const boxes = parseFloat(row['boxes'] || '0') || 0;
      const cartonQty = parseFloat(row['carton_qty'] || row['cartonqty'] || '0') || 0;
      const totalQty = parseFloat(row['total_qty'] || row['qty'] || row['quantity'] || '0') || 0;
      const stockStatus = this._str(row['stock_status']).toLowerCase();

      const isPending = stockStatus === 'pending_count';
      const boxesOnly = boxes > 0 && cartonQty === 0 && totalQty === 0 && !isPending;

      let quantity: number;
      let calcBoxes: number;
      let calcUnits: number;

      if (isPending) {
        quantity = 0; calcBoxes = boxes; calcUnits = 1;
      } else if (boxes > 0 && cartonQty > 0) {
        quantity = boxes * cartonQty; calcBoxes = boxes; calcUnits = cartonQty;
      } else if (totalQty > 0) {
        quantity = totalQty;
        calcUnits = cartonQty > 0 ? cartonQty : 1;
        calcBoxes = cartonQty > 0 ? Math.floor(totalQty / cartonQty) : totalQty;
      } else if (boxesOnly) {
        quantity = 0; calcBoxes = boxes; calcUnits = 1;
      } else {
        quantity = 0; calcBoxes = 0; calcUnits = 1;
      }

      const key = `${skuCode}||${locationCode}`;
      if (!groupMap.has(key)) groupMap.set(key, []);
      groupMap.get(key)!.push({ rowNum, skuCode, locationCode, calcBoxes, calcUnits, quantity, isPending, boxesOnly });
    }

    // ── Step 2: write each group as one inventory record ───────────────────
    for (const [, rows] of groupMap) {
      const { skuCode, locationCode } = rows[0];

      const sku = await this.skuModel.findOne({ sku: skuCode });
      const location = await this.locationModel.findOne({ code: locationCode });

      if (!sku || !location) {
        for (const r of rows) {
          errors.push({ row: r.rowNum, message: `SKU ${skuCode} 或库位 ${locationCode} 不存在` });
          skipped++;
        }
        continue;
      }

      const isPending = rows.some((r) => r.isPending);
      const boxesOnly = rows.every((r) => r.boxesOnly);

      // Build configurations: one entry per distinct unitsPerBox, merging boxes
      // Filter out rows that are pure pending/boxesOnly (no real config)
      const configRows = rows.filter((r) => !r.isPending && !r.boxesOnly && r.calcBoxes > 0);
      const boxesOnlyRows = rows.filter((r) => r.boxesOnly);

      let configurations: { boxes: number; unitsPerBox: number }[] = [];
      let totalBoxes = 0;
      let totalQuantity = 0;

      if (configRows.length > 0) {
        // Same unitsPerBox + different boxes → keep max boxes
        // Same unitsPerBox + same boxes → treat as duplicate, keep one (no accumulation)
        const cfgMap = new Map<number, Set<number>>();
        for (const r of configRows) {
          if (!cfgMap.has(r.calcUnits)) cfgMap.set(r.calcUnits, new Set());
          cfgMap.get(r.calcUnits)!.add(r.calcBoxes);
        }
        configurations = Array.from(cfgMap.entries()).map(([unitsPerBox, boxSet]) => ({
          boxes: Math.max(...boxSet),
          unitsPerBox,
        }));
        totalBoxes = configurations.reduce((s, c) => s + c.boxes, 0);
        totalQuantity = configurations.reduce((s, c) => s + c.boxes * c.unitsPerBox, 0);
      } else if (boxesOnlyRows.length > 0) {
        totalBoxes = boxesOnlyRows.reduce((s, r) => s + r.calcBoxes, 0);
      }

      // If only one config, store as flat boxes/unitsPerBox (no configurations array needed)
      const useConfigurations = configurations.length > 1;
      const flatBoxes = useConfigurations ? totalBoxes : (configurations[0]?.boxes ?? totalBoxes);
      const flatUnits = useConfigurations ? 1 : (configurations[0]?.unitsPerBox ?? 1);

      const existing = await this.inventoryModel.findOne({ skuId: sku._id, locationId: location._id });
      if (existing) {
        existing.skuCode = skuCode;
        existing.boxes = flatBoxes;
        existing.unitsPerBox = flatUnits;
        existing.configurations = useConfigurations ? configurations : [];
        existing.quantity = totalQuantity;
        existing.boxesOnlyMode = boxesOnly;
        existing.stockStatus = isPending ? 'pending_count' : 'confirmed';
        existing.quantityUnknown = isPending;
        await existing.save();
        updated++;
      } else {
        await this.inventoryModel.create({
          skuId: sku._id,
          skuCode,
          locationId: location._id,
          boxes: flatBoxes,
          unitsPerBox: flatUnits,
          configurations: useConfigurations ? configurations : [],
          quantity: totalQuantity,
          boxesOnlyMode: boxesOnly,
          stockStatus: isPending ? 'pending_count' : 'confirmed',
          quantityUnknown: isPending,
        });
        created++;
      }
    }

    await this.importLogModel.create({
      userId: user._id,
      userName: user.name,
      importType: 'inventory',
      filename,
      total: records.length,
      created,
      updated,
      skipped,
      importErrors: errors,
    });

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'import',
      entity: 'inventory',
      description: `库存导入 [${filename}]: 新增 ${created}，更新 ${updated}，跳过 ${skipped}`,
    });

    return { total: records.length, created, updated, skipped, errors };
  }

  // ─── Logs ─────────────────────────────────────────────────────────────────────

  async getLogs({ importType, page = 1, limit = 30 }: { importType?: string; page?: number; limit?: number }) {
    const filter: any = {};
    if (importType) filter.importType = importType;

    const total = await this.importLogModel.countDocuments(filter);
    const records = await this.importLogModel
      .find(filter)
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .lean();

    return { records, total, page };
  }

  async exportLog(id: string): Promise<Buffer> {
    const log = await this.importLogModel.findById(id).lean();
    if (!log) throw new NotFoundException('导入记录不存在');

    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('导入详情');

    sheet.addRow(['文件名', log.filename]);
    sheet.addRow(['类型', log.importType]);
    sheet.addRow(['总行数', log.total]);
    sheet.addRow(['新增', log.created]);
    sheet.addRow(['更新', log.updated]);
    sheet.addRow(['跳过', log.skipped]);
    sheet.addRow([]);
    sheet.addRow(['行号', '错误信息']);

    for (const e of log.importErrors || []) {
      sheet.addRow([e.row, e.message]);
    }

    const buffer = await workbook.xlsx.writeBuffer();
    return Buffer.from(buffer);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  private _parseCsv(buffer: Buffer, filename = ''): any[] {
    try {
      return parse(buffer, {
        columns: true,
        skip_empty_lines: true,
        trim: true,
        bom: true,
      });
    } catch {
      throw new BadRequestException('CSV 文件解析失败，请检查格式');
    }
  }

  private async _parseXlsx(buffer: Buffer): Promise<any[]> {
    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(buffer as any);
    const sheet = workbook.worksheets[0];
    if (!sheet) throw new BadRequestException('Excel 文件中没有工作表');

    const rows: any[] = [];
    let headers: string[] = [];

    sheet.eachRow((row, rowNumber) => {
      const values = (row.values as any[]).slice(1); // remove leading undefined
      if (rowNumber === 1) {
        headers = values.map((v) => (v ?? '').toString().trim());
      } else {
        const obj: any = {};
        headers.forEach((h, i) => {
          obj[h] = values[i] ?? '';
        });
        rows.push(obj);
      }
    });

    return rows;
  }

  private async _parseFile(buffer: Buffer, filename: string): Promise<any[]> {
    if (filename.toLowerCase().endsWith('.xlsx')) {
      return this._parseXlsx(buffer);
    }
    return this._parseCsv(buffer, filename);
  }

  private _str(val: any): string {
    return (val ?? '').toString().trim();
  }
}
