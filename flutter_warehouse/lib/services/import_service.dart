import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'api_service.dart';

class ImportError {
  final int row;
  final String message;
  ImportError({required this.row, required this.message});
  factory ImportError.fromJson(Map<String, dynamic> json) =>
      ImportError(row: json['row'] ?? 0, message: json['message'] ?? '');
}

class ImportResult {
  final int total;
  final int created;
  final int updated;
  final int skipped;
  final List<ImportError> errors;

  ImportResult({
    required this.total,
    required this.created,
    required this.updated,
    required this.skipped,
    required this.errors,
  });

  factory ImportResult.fromJson(Map<String, dynamic> json) => ImportResult(
        total: json['total'] ?? 0,
        created: json['created'] ?? 0,
        updated: json['updated'] ?? 0,
        skipped: json['skipped'] ?? 0,
        errors: (json['errors'] as List?)
                ?.map((e) => ImportError.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  bool get hasErrors => errors.isNotEmpty;
  bool get isClean => errors.isEmpty && skipped == 0;
}

class PreviewRow {
  final int row;
  final String action; // 'create' | 'update' | 'skip'
  final String summary;
  final String? error;

  PreviewRow({
    required this.row,
    required this.action,
    required this.summary,
    this.error,
  });

  factory PreviewRow.fromJson(Map<String, dynamic> json) => PreviewRow(
        row: json['row'] ?? 0,
        action: json['action'] ?? 'skip',
        summary: json['summary'] ?? '',
        error: json['error'] as String?,
      );

  bool get isSkipped => action == 'skip';
  bool get isCreate => action == 'create';
  bool get isUpdate => action == 'update';
}

class ImportPreview {
  final int total;
  final int willCreate;
  final int willUpdate;
  final int willSkip;
  final int errorCount;
  final List<PreviewRow> rows;

  ImportPreview({
    required this.total,
    required this.willCreate,
    required this.willUpdate,
    required this.willSkip,
    required this.errorCount,
    required this.rows,
  });

  factory ImportPreview.fromJson(Map<String, dynamic> json) => ImportPreview(
        total: json['total'] ?? 0,
        willCreate: json['willCreate'] ?? 0,
        willUpdate: json['willUpdate'] ?? 0,
        willSkip: json['willSkip'] ?? 0,
        errorCount: json['errorCount'] ?? 0,
        rows: (json['rows'] as List?)
                ?.map((e) => PreviewRow.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  bool get hasErrors => errorCount > 0;
  bool get hasValidRows => willCreate > 0 || willUpdate > 0;
}

// ─── Import Log ──────────────────────────────────────────────────────────────

class ImportLogError {
  final int row;
  final String message;
  ImportLogError({required this.row, required this.message});
  factory ImportLogError.fromJson(Map<String, dynamic> json) =>
      ImportLogError(row: json['row'] ?? 0, message: json['message'] ?? '');
}

class ImportLogRecord {
  final String id;
  final String userId;
  final String userName;
  final String importType; // skus | locations | inventory
  final String filename;
  final int total;
  final int created;
  final int updated;
  final int skipped;
  final List<ImportLogError> errors;
  final DateTime createdAt;

  ImportLogRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.importType,
    required this.filename,
    required this.total,
    required this.created,
    required this.updated,
    required this.skipped,
    required this.errors,
    required this.createdAt,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isClean => errors.isEmpty && skipped == 0;

  String get importTypeLabel => switch (importType) {
        'skus' => 'SKU 主档',
        'locations' => '库位主档',
        'inventory' => '库存明细',
        'sku-barcode-update' => 'SKU 条形码更新',
        'sku-carton-qty-update' => 'SKU 箱规更新',
        _ => importType,
      };

  factory ImportLogRecord.fromJson(Map<String, dynamic> json) =>
      ImportLogRecord(
        id: json['_id'] ?? '',
        userId: json['userId'] ?? '',
        userName: json['userName'] ?? '',
        importType: json['importType'] ?? '',
        filename: json['filename'] ?? '',
        total: json['total'] ?? 0,
        created: json['created'] ?? 0,
        updated: json['updated'] ?? 0,
        skipped: json['skipped'] ?? 0,
        errors: (json['importErrors'] as List?)
                ?.map((e) => ImportLogError.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt']).toLocal()
            : DateTime.now(),
      );
}

// ─── Service ─────────────────────────────────────────────────────────────────

class ImportService {
  final _api = ApiService.instance.dio;

  // ─── Validate (no write) ─────────────────────────────────────────────────

  Future<ImportPreview> validateSkus(List<int> bytes, String filename) async {
    final response = await _api.post('/import/skus/validate',
        data: FormData.fromMap(
            {'file': MultipartFile.fromBytes(bytes, filename: filename)}));
    return ImportPreview.fromJson(response.data);
  }

  Future<ImportPreview> validateLocations(
      List<int> bytes, String filename) async {
    final response = await _api.post('/import/locations/validate',
        data: FormData.fromMap(
            {'file': MultipartFile.fromBytes(bytes, filename: filename)}));
    return ImportPreview.fromJson(response.data);
  }

  Future<ImportPreview> validateInventory(
      List<int> bytes, String filename) async {
    final response = await _api.post('/import/inventory/validate',
        data: FormData.fromMap(
            {'file': MultipartFile.fromBytes(bytes, filename: filename)}));
    return ImportPreview.fromJson(response.data);
  }

  // ─── Import (write) ──────────────────────────────────────────────────────

  Future<ImportPreview> validateSkuBarcodeUpdate(List<int> bytes, String filename) async {
    final response = await _api.post('/import/sku-barcode-update/validate',
        data: FormData.fromMap({'file': MultipartFile.fromBytes(bytes, filename: filename)}));
    return ImportPreview.fromJson(response.data);
  }

  Future<ImportPreview> validateSkuCartonQtyUpdate(List<int> bytes, String filename) async {
    final response = await _api.post('/import/sku-carton-qty-update/validate',
        data: FormData.fromMap({'file': MultipartFile.fromBytes(bytes, filename: filename)}));
    return ImportPreview.fromJson(response.data);
  }

  // ─── Import (write) ──────────────────────────────────────────────────────
  // (skuBarcodeUpdate / skuCartonQtyUpdate declared below)

  Future<ImportResult> importSkus(List<int> bytes, String filename) async {
    final response = await _api.post('/import/skus',
        data: FormData.fromMap(
            {'file': MultipartFile.fromBytes(bytes, filename: filename)}));
    return ImportResult.fromJson(response.data);
  }

  Future<ImportResult> importLocations(List<int> bytes, String filename) async {
    final response = await _api.post('/import/locations',
        data: FormData.fromMap(
            {'file': MultipartFile.fromBytes(bytes, filename: filename)}));
    return ImportResult.fromJson(response.data);
  }

  Future<ImportResult> importInventory(List<int> bytes, String filename) async {
    final response = await _api.post('/import/inventory',
        data: FormData.fromMap(
            {'file': MultipartFile.fromBytes(bytes, filename: filename)}));
    return ImportResult.fromJson(response.data);
  }

  Future<ImportResult> importSkuBarcodeUpdate(List<int> bytes, String filename) async {
    final response = await _api.post('/import/sku-barcode-update',
        data: FormData.fromMap({'file': MultipartFile.fromBytes(bytes, filename: filename)}));
    return ImportResult.fromJson(response.data);
  }

  Future<ImportResult> importSkuCartonQtyUpdate(List<int> bytes, String filename) async {
    final response = await _api.post('/import/sku-carton-qty-update',
        data: FormData.fromMap({'file': MultipartFile.fromBytes(bytes, filename: filename)}));
    return ImportResult.fromJson(response.data);
  }

  // ─── Import Logs ─────────────────────────────────────────────────────────

  Future<({List<ImportLogRecord> records, int total, int page})> getLogs({
    String? importType,
    int page = 1,
    int limit = 30,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (importType != null) params['importType'] = importType;
    final response = await _api.get('/import/logs', queryParameters: params);
    final data = response.data as Map<String, dynamic>;
    final records = (data['records'] as List)
        .map((e) => ImportLogRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    return (records: records, total: data['total'] as int, page: data['page'] as int);
  }

  // ─── Export Log ──────────────────────────────────────────────────────────

  /// Downloads a detailed Excel report for the given import log record.
  Future<void> exportLog(ImportLogRecord record) async {
    String token = AuthTokenCache.token ?? '';
    if (token.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString(AppConstants.tokenKey) ?? '';
    }
    final fmt = DateFormat('yyyyMMdd_HHmm');
    final filename = 'import_${record.importType}_${fmt.format(record.createdAt)}.xlsx';
    final url = '${AppConstants.baseUrl}/import/logs/${record.id}/export';

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/$filename';
    await Dio().download(url, filePath,
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    await Share.shareXFiles([XFile(filePath)]);
  }

  // ─── Templates ───────────────────────────────────────────────────────────

  /// Downloads a CSV template. barcode column is prefixed with tab to encourage
  /// Excel to treat it as text (reduces scientific-notation mangling).
  Future<void> downloadTemplate(String type) async {
    late String content;
    late String filename;

    switch (type) {
      case 'skus':
        // Note: barcode column uses text format hint in the example row
        content = 'sku_code,name,barcode,default_carton_qty,status,sku_level\r\n'
            'ABC-001,产品名称示例,1234567890123,12,active,variant\r\n'
            'DEF-002,另一个产品,,6,active,variant\r\n'
            'MAIN-001,主码大类产品,,,,main\r\n';
        filename = 'sku_master_template.csv';

      case 'locations':
        content = 'location_code,description,status\r\n'
            'A1A,货架A区1排,active\r\n'
            'B2B,货架B区2排,active\r\n'
            'C3C-OLD,已停用库位,inactive\r\n';
        filename = 'location_master_template.csv';

      case 'inventory':
        // 8 columns: sku_code, location_code, boxes, carton_qty, total_qty, stock_status, note, inventory_type
        content =
            'sku_code,location_code,boxes,carton_qty,total_qty,stock_status,note,inventory_type\r\n'
            'ABC-001,A1A,10,12,,confirmed,按箱规导入示例,specific\r\n'
            'ABC-001,A1A,3,100,,confirmed,多箱规合并示例,specific\r\n'
            'DEF-002,B2B,,,120,confirmed,按总件数导入示例,specific\r\n'
            'XYZ-003,C1A,,,0,pending_count,待清点,specific\r\n'
            'MAIN-001,D1A,,,,,,generic\r\n';
        filename = 'inventory_detail_template.csv';

      case 'sku-barcode-update':
        content = 'sku_code,barcode\r\n'
            'ABC-001,1234567890123\r\n'
            'DEF-002,9876543210987\r\n';
        filename = 'sku_barcode_update_template.csv';

      case 'sku-carton-qty-update':
        content = 'sku_code,default_carton_qty\r\n'
            'ABC-001,12\r\n'
            'DEF-002,6\r\n';
        filename = 'sku_carton_qty_update_template.csv';

      default:
        return;
    }

    const bom = '\uFEFF';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString('$bom$content', encoding: utf8);
    await Share.shareXFiles([XFile(file.path)]);
  }
}
