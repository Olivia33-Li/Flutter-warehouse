import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../services/import_service.dart';

class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('批量导入'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'SKU 主档'),
              Tab(text: '库位主档'),
              Tab(text: '库存明细'),
              Tab(text: '导入记录'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ImportTab(
              type: 'skus',
              title: 'SKU 主档导入',
              description: '用于批量新增或更新 SKU 基础资料。\n'
                  '已存在的 SKU 将被更新（upsert），不会重复创建。',
              columns: [
                _ColDef('sku_code', _ColReq.required, 'SKU 编码，全大写'),
                _ColDef('name', _ColReq.optional, '商品名称'),
                _ColDef('barcode', _ColReq.optional, '条形码（必须以文本格式保存，防止科学计数法）'),
                _ColDef('default_carton_qty', _ColReq.optional, '默认箱规（正整数），供库存导入时参考'),
                _ColDef('status', _ColReq.optional, 'active（在用）或 inactive（停用），默认 active'),
              ],
              notes: [
                '条形码注意：在 Excel 中请将条形码列格式设为【文本】后再填入数据，'
                    '否则 Excel 会将长数字转为科学计数法（如 1.23E+12）导致数据损坏。',
              ],
            ),
            _ImportTab(
              type: 'locations',
              title: '库位主档导入',
              description: '用于批量新增或更新库位基础资料。\n'
                  '已存在的库位将被更新（upsert），不会重复创建。',
              columns: [
                _ColDef('location_code', _ColReq.required, '库位编码，全大写'),
                _ColDef('description', _ColReq.optional, '库位描述'),
                _ColDef('status', _ColReq.optional, 'active（在用）或 inactive（停用），默认 active'),
              ],
            ),
            _ImportTab(
              type: 'inventory',
              title: '库存明细导入',
              description: '用于批量录入库存数据。\n'
                  'SKU 和库位必须已存在（请先完成主档导入）。\n'
                  '已有记录将被替换（upsert），不会累加。',
              columns: [
                _ColDef('sku_code', _ColReq.required, 'SKU 编码'),
                _ColDef('location_code', _ColReq.required, '库位编码'),
                _ColDef('boxes', _ColReq.optional, '箱数，需与 carton_qty 同时填写'),
                _ColDef('carton_qty', _ColReq.optional, '每箱件数，需与 boxes 同时填写'),
                _ColDef('total_qty', _ColReq.optional, '总件数，仅填此项时按总件数导入'),
                _ColDef('stock_status', _ColReq.optional, 'confirmed / pending_count / temporary，默认 confirmed'),
                _ColDef('note', _ColReq.optional, '备注'),
              ],
              notes: [
                '数量规则：填写 boxes+carton_qty（按箱规）或 total_qty（按总件数）。\n'
                    '若数量字段均为空或只填写了部分，系统将创建"待补充数量"记录，不报错。\n'
                    '若同时填写了 total_qty，系统会校验 total_qty == boxes × carton_qty，不一致则报错。',
                '多箱规：同一 SKU+库位 可在文件中出现多行（不同箱规），系统自动合并为多箱规记录。\n'
                    '如果同一 SKU+库位+箱规 出现两次，系统会报重复错误（不静默合并）。',
              ],
            ),
            const _ImportLogsTab(),
          ],
        ),
      ),
    );
  }
}

enum _ColReq { required, optional, eitherA, eitherB }

class _ColDef {
  final String name;
  final _ColReq req;
  final String desc;
  const _ColDef(this.name, this.req, this.desc);
}

// ─── State machine ────────────────────────────────────────────────────────────
enum _Phase { idle, validating, preview, importing, done }

class _ImportTab extends StatefulWidget {
  final String type;
  final String title;
  final String description;
  final List<_ColDef> columns;
  final List<String> notes;

  const _ImportTab({
    required this.type,
    required this.title,
    required this.description,
    required this.columns,
    this.notes = const [],
  });

  @override
  State<_ImportTab> createState() => _ImportTabState();
}

class _ImportTabState extends State<_ImportTab>
    with AutomaticKeepAliveClientMixin {
  final _service = ImportService();

  _Phase _phase = _Phase.idle;
  ImportPreview? _preview;
  ImportResult? _result;
  String? _error;

  // Hold the file bytes/name across the two steps
  List<int>? _pendingBytes;
  String? _pendingFilename;

  @override
  bool get wantKeepAlive => true;

  // ── Step 1: pick file and validate ──────────────────────────────────────

  Future<void> _pickAndValidate() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    if (file.bytes == null) return;

    setState(() {
      _phase = _Phase.validating;
      _error = null;
      _preview = null;
      _result = null;
      _pendingBytes = file.bytes;
      _pendingFilename = file.name;
    });

    try {
      ImportPreview preview;
      switch (widget.type) {
        case 'skus':
          preview = await _service.validateSkus(file.bytes!, file.name);
        case 'locations':
          preview = await _service.validateLocations(file.bytes!, file.name);
        case 'inventory':
          preview = await _service.validateInventory(file.bytes!, file.name);
        default:
          return;
      }
      setState(() {
        _preview = preview;
        _phase = _Phase.preview;
      });
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      setState(() {
        _error = msg is List ? msg.join(', ') : (msg ?? '校验失败，请检查文件格式');
        _phase = _Phase.idle;
      });
    } catch (e) {
      setState(() {
        _error = '校验失败: $e';
        _phase = _Phase.idle;
      });
    }
  }

  // ── Step 2: confirm and import ───────────────────────────────────────────

  Future<void> _confirmImport() async {
    if (_pendingBytes == null || _pendingFilename == null) return;

    setState(() {
      _phase = _Phase.importing;
      _error = null;
    });

    try {
      ImportResult result;
      switch (widget.type) {
        case 'skus':
          result = await _service.importSkus(_pendingBytes!, _pendingFilename!);
        case 'locations':
          result =
              await _service.importLocations(_pendingBytes!, _pendingFilename!);
        case 'inventory':
          result =
              await _service.importInventory(_pendingBytes!, _pendingFilename!);
        default:
          return;
      }
      setState(() {
        _result = result;
        _phase = _Phase.done;
      });
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      setState(() {
        _error = msg is List ? msg.join(', ') : (msg ?? '导入失败，请检查文件格式');
        _phase = _Phase.preview; // stay on preview so user can retry
      });
    } catch (e) {
      setState(() {
        _error = '导入失败: $e';
        _phase = _Phase.preview;
      });
    }
  }

  void _reset() {
    setState(() {
      _phase = _Phase.idle;
      _preview = null;
      _result = null;
      _error = null;
      _pendingBytes = null;
      _pendingFilename = null;
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Column definition card ────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(widget.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ]),
                const SizedBox(height: 8),
                Text(widget.description,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.5)),
                const SizedBox(height: 14),
                const Text('模板列说明：',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                _colTable(context),
                // Notes
                if (widget.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...widget.notes.map((note) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 16,
                                color: Colors.orange.shade700),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(note,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade800,
                                      height: 1.5)),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Action buttons ────────────────────────────────────────────────
        _buildActionRow(),

        // ── Error banner ──────────────────────────────────────────────────
        if (_error != null) ...[
          const SizedBox(height: 12),
          _errorBanner(_error!),
        ],

        // ── Preview panel ─────────────────────────────────────────────────
        if (_phase == _Phase.preview && _preview != null) ...[
          const SizedBox(height: 12),
          _PreviewPanel(
            preview: _preview!,
            filename: _pendingFilename ?? '',
          ),
        ],

        // ── Result panel ──────────────────────────────────────────────────
        if (_phase == _Phase.done && _result != null) ...[
          const SizedBox(height: 12),
          _ResultPanel(result: _result!),
        ],
      ],
    );
  }

  Widget _buildActionRow() {
    final busy = _phase == _Phase.validating || _phase == _Phase.importing;

    if (_phase == _Phase.preview) {
      // Two buttons: re-select file + confirm import
      return Row(children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('重新选择'),
          onPressed: _reset,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: Text(_preview!.hasValidRows
                ? '确认导入 (${_preview!.willCreate + _preview!.willUpdate} 条)'
                : '无可导入数据'),
            style: FilledButton.styleFrom(
              backgroundColor: _preview!.hasValidRows
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            onPressed: _preview!.hasValidRows ? _confirmImport : null,
          ),
        ),
      ]);
    }

    if (_phase == _Phase.done) {
      return Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('重新导入'),
            onPressed: _reset,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('下载模板'),
            onPressed: () => _service.downloadTemplate(widget.type),
          ),
        ),
      ]);
    }

    // idle / validating / importing
    return Row(children: [
      Expanded(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.download_outlined, size: 18),
          label: const Text('下载模板'),
          onPressed: busy ? null : () => _service.downloadTemplate(widget.type),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: FilledButton.icon(
          icon: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.upload_file, size: 18),
          label: Text(_phase == _Phase.validating
              ? '校验中…'
              : _phase == _Phase.importing
                  ? '导入中…'
                  : '选择文件'),
          onPressed: busy ? null : _pickAndValidate,
        ),
      ),
    ]);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _colTable(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: FlexColumnWidth(),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: [_th('列名'), _th('必填'), _th('说明')],
        ),
        ...widget.columns.map((c) => TableRow(children: [
              _td(c.name, mono: true, color: primary),
              _tdReq(c.req),
              _td(c.desc),
            ])),
      ],
    );
  }

  Widget _th(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      );

  Widget _td(String text, {bool mono = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontFamily: mono ? 'monospace' : null)),
      );

  Widget _tdReq(_ColReq req) {
    final (label, color) = switch (req) {
      _ColReq.required => ('必填', Colors.red.shade600),
      _ColReq.eitherA => ('二选A', Colors.deepOrange.shade600),
      _ColReq.eitherB => ('二选B', Colors.deepOrange.shade600),
      _ColReq.optional => ('可选', Colors.grey.shade500),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(label, style: TextStyle(fontSize: 12, color: color)),
    );
  }

  Widget _errorBanner(String msg) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(msg, style: TextStyle(color: Colors.red.shade700))),
        ]),
      );
}

// ─── Preview Panel ────────────────────────────────────────────────────────────

class _PreviewPanel extends StatelessWidget {
  final ImportPreview preview;
  final String filename;
  const _PreviewPanel({required this.preview, required this.filename});

  @override
  Widget build(BuildContext context) {
    final hasErrors = preview.hasErrors;
    final hasValid = preview.hasValidRows;

    Color borderColor;
    Color bgColor;
    if (!hasErrors) {
      borderColor = Colors.green.shade200;
      bgColor = Colors.green.shade50;
    } else if (hasValid) {
      borderColor = Colors.orange.shade200;
      bgColor = Colors.orange.shade50;
    } else {
      borderColor = Colors.red.shade200;
      bgColor = Colors.red.shade50;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(
                hasErrors
                    ? (hasValid
                        ? Icons.warning_amber_outlined
                        : Icons.error_outline)
                    : Icons.check_circle_outline,
                color: hasErrors
                    ? (hasValid
                        ? Colors.orange.shade700
                        : Colors.red.shade600)
                    : Colors.green.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasErrors
                          ? (hasValid ? '校验完成（含部分错误）' : '校验完成（全部行有错误）')
                          : '校验通过，可以导入',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hasErrors
                              ? (hasValid
                                  ? Colors.orange.shade800
                                  : Colors.red.shade700)
                              : Colors.green.shade700),
                    ),
                    Text('文件: $filename',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ]),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Wrap(spacing: 16, runSpacing: 4, children: [
              _stat('共', preview.total, Colors.grey.shade700),
              _stat('待创建', preview.willCreate, Colors.green.shade700),
              _stat('待更新', preview.willUpdate, Colors.blue.shade700),
              if (preview.willSkip > 0)
                _stat('跳过', preview.willSkip, Colors.orange.shade700),
              if (preview.hasErrors)
                _stat('错误', preview.errorCount, Colors.red.shade700),
            ]),
          ),

          // Error rows
          if (preview.hasErrors) ...[
            Divider(height: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('错误详情：',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700)),
                  const SizedBox(height: 6),
                  ...preview.rows
                      .where((r) => r.isSkipped)
                      .take(20)
                      .map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('第 ${r.row} 行  ',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade600,
                                        fontFamily: 'monospace')),
                                Expanded(
                                    child: Text(r.error ?? r.summary,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade800))),
                              ],
                            ),
                          )),
                  if (preview.errorCount > 20)
                    Text(
                        '… 还有 ${preview.errorCount - 20} 条错误（请修正文件后重新选择）',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],

          // Valid rows (preview of what will be written)
          if (preview.hasValidRows) ...[
            Divider(height: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('将写入数据预览：',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  ...preview.rows
                      .where((r) => !r.isSkipped)
                      .take(30)
                      .map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 2, right: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: r.isCreate
                                        ? Colors.green.shade100
                                        : Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    r.isCreate ? '新建' : '更新',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: r.isCreate
                                            ? Colors.green.shade700
                                            : Colors.blue.shade700),
                                  ),
                                ),
                                Expanded(
                                    child: Text(r.summary,
                                        style: const TextStyle(fontSize: 12))),
                              ],
                            ),
                          )),
                  if (preview.willCreate + preview.willUpdate > 30)
                    Text(
                        '… 还有 ${preview.willCreate + preview.willUpdate - 30} 条（确认后将全部写入）',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, int value, Color color) => RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: color),
          children: [
            TextSpan(
                text: '$value ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: label),
          ],
        ),
      );
}

// ─── Result Panel ─────────────────────────────────────────────────────────────

class _ResultPanel extends StatelessWidget {
  final ImportResult result;
  const _ResultPanel({required this.result});

  @override
  Widget build(BuildContext context) {
    final allOk = result.isClean;
    return Container(
      decoration: BoxDecoration(
        color: allOk ? Colors.green.shade50 : Colors.orange.shade50,
        border: Border.all(
            color: allOk ? Colors.green.shade200 : Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(
                allOk
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_outlined,
                color: allOk ? Colors.green.shade600 : Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                allOk ? '导入完成' : '导入完成（有部分问题）',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: allOk
                      ? Colors.green.shade700
                      : Colors.orange.shade800,
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Wrap(spacing: 16, runSpacing: 4, children: [
              _stat('共', result.total, Colors.grey.shade700),
              _stat('新建', result.created, Colors.green.shade700),
              _stat('更新', result.updated, Colors.blue.shade700),
              if (result.skipped > 0)
                _stat('跳过', result.skipped, Colors.orange.shade700),
              if (result.hasErrors)
                _stat('错误', result.errors.length, Colors.red.shade700),
            ]),
          ),
          if (result.hasErrors) ...[
            Divider(
                height: 1,
                color:
                    allOk ? Colors.green.shade200 : Colors.orange.shade200),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('行级错误详情：',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800)),
                  const SizedBox(height: 6),
                  ...result.errors.take(20).map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('第 ${e.row} 行  ',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade600,
                                      fontFamily: 'monospace')),
                              Expanded(
                                  child: Text(e.message,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade800))),
                            ],
                          ),
                        ),
                      ),
                  if (result.errors.length > 20)
                    Text(
                        '… 还有 ${result.errors.length - 20} 条错误',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, int value, Color color) => RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: color),
          children: [
            TextSpan(
                text: '$value ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: label),
          ],
        ),
      );
}

// ─── Import Logs Tab ──────────────────────────────────────────────────────────

class _ImportLogsTab extends StatefulWidget {
  const _ImportLogsTab();

  @override
  State<_ImportLogsTab> createState() => _ImportLogsTabState();
}

class _ImportLogsTabState extends State<_ImportLogsTab>
    with AutomaticKeepAliveClientMixin {
  final _service = ImportService();

  List<ImportLogRecord> _records = [];
  int _total = 0;
  int _page = 1;
  bool _loading = false;
  String? _error;
  String? _filterType;

  static const _typeOptions = [
    (null, '全部'),
    ('skus', 'SKU 主档'),
    ('locations', '库位主档'),
    ('inventory', '库存明细'),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _page = 1;
      _records = [];
    }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _service.getLogs(
        importType: _filterType,
        page: _page,
        limit: 30,
      );
      setState(() {
        _records = reset ? result.records : [..._records, ...result.records];
        _total = result.total;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    spacing: 6,
                    children: _typeOptions.map((opt) {
                      final selected = _filterType == opt.$1;
                      return FilterChip(
                        label: Text(opt.$2),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _filterType = opt.$1);
                          _load(reset: true);
                        },
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: '刷新',
                onPressed: () => _load(reset: true),
              ),
            ],
          ),
        ),

        if (!_loading && _records.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('共 $_total 条记录',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ),
          ),

        Expanded(
          child: _loading && _records.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 8),
                          TextButton(
                              onPressed: () => _load(reset: true),
                              child: const Text('重试')),
                        ],
                      ),
                    )
                  : _records.isEmpty
                      ? Center(
                          child: Text('暂无导入记录',
                              style: TextStyle(color: Colors.grey.shade500)))
                      : RefreshIndicator(
                          onRefresh: () => _load(reset: true),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                            itemCount:
                                _records.length + (_records.length < _total ? 1 : 0),
                            itemBuilder: (ctx, i) {
                              if (i == _records.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: TextButton(
                                      onPressed: () { _page++; _load(); },
                                      child: const Text('加载更多'),
                                    ),
                                  ),
                                );
                              }
                              return _LogCard(record: _records[i]);
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

// ─── Log Card ─────────────────────────────────────────────────────────────────

class _LogCard extends StatelessWidget {
  final ImportLogRecord record;
  const _LogCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MM-dd HH:mm');
    final hasErrors = record.hasErrors;
    final isClean = record.isClean;

    final Color borderColor;
    final Color bgColor;
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    if (isClean) {
      borderColor = Colors.green.shade200;
      bgColor = Colors.green.shade50;
      statusColor = Colors.green.shade700;
      statusLabel = '成功';
      statusIcon = Icons.check_circle_outline;
    } else if (hasErrors && record.created + record.updated > 0) {
      borderColor = Colors.orange.shade200;
      bgColor = Colors.orange.shade50;
      statusColor = Colors.orange.shade700;
      statusLabel = '部分成功';
      statusIcon = Icons.warning_amber_outlined;
    } else if (hasErrors && record.created + record.updated == 0) {
      borderColor = Colors.red.shade200;
      bgColor = Colors.red.shade50;
      statusColor = Colors.red.shade600;
      statusLabel = '全部失败';
      statusIcon = Icons.error_outline;
    } else {
      borderColor = Colors.blue.shade200;
      bgColor = Colors.blue.shade50;
      statusColor = Colors.blue.shade700;
      statusLabel = '完成（有跳过）';
      statusIcon = Icons.info_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor),
      ),
      color: bgColor,
      elevation: 0,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
        childrenPadding: EdgeInsets.zero,
        leading: Icon(statusIcon, color: statusColor, size: 22),
        title: Row(
          children: [
            Expanded(
              child: Text(record.importTypeLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(statusLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor)),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(record.filename,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              Text(fmt.format(record.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(width: 8),
              Text(record.userName,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ]),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    _stat('共', record.total, Colors.grey.shade700),
                    _stat('新建', record.created, Colors.green.shade700),
                    _stat('更新', record.updated, Colors.blue.shade700),
                    if (record.skipped > 0)
                      _stat('跳过', record.skipped, Colors.orange.shade700),
                    if (hasErrors)
                      _stat('错误', record.errors.length, Colors.red.shade600),
                  ],
                ),
                if (hasErrors) ...[
                  const SizedBox(height: 10),
                  Text('行级错误详情：',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700)),
                  const SizedBox(height: 6),
                  ...record.errors.take(20).map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('第 ${e.row} 行  ',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade600,
                                    fontFamily: 'monospace')),
                            Expanded(
                              child: Text(e.message,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade800)),
                            ),
                          ],
                        ),
                      )),
                  if (record.errors.length > 20)
                    Text('… 还有 ${record.errors.length - 20} 条错误',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, Color color) => RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: color),
          children: [
            TextSpan(
                text: '$value ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: label),
          ],
        ),
      );
}
