import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../services/import_service.dart';
import '../../l10n/app_localizations.dart';

// ─── Import hub ───────────────────────────────────────────────────────────────

class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  static List<_HubEntry> _buildEntries(AppLocalizations l10n) => [
    _HubEntry(
      type: 'skus',
      label: l10n.importSkuMasterLabel,
      subtitle: l10n.importSkuMasterSubtitle,
      icon: Icons.inventory_2_outlined,
      avatarBg: const Color(0xFFEEF1FE),
      iconColor: const Color(0xFF4A6CF7),
    ),
    _HubEntry(
      type: 'locations',
      label: l10n.importLocationMasterLabel,
      subtitle: l10n.importLocationMasterSubtitle,
      icon: Icons.shelves,
      avatarBg: const Color(0xFFEEF6F0),
      iconColor: const Color(0xFF4EBB6A),
    ),
    _HubEntry(
      type: 'inventory',
      label: l10n.importInventoryLabel,
      subtitle: l10n.importInventorySubtitle,
      icon: Icons.table_chart_outlined,
      avatarBg: const Color(0xFFFDF5E8),
      iconColor: const Color(0xFFE09030),
    ),
    _HubEntry(
      type: 'sku-barcode-update',
      label: l10n.importSkuBarcodeLabel,
      subtitle: l10n.importSkuBarcodeSubtitle,
      icon: Icons.qr_code_outlined,
      avatarBg: const Color(0xFFF3EEFC),
      iconColor: const Color(0xFF9A6CF7),
    ),
    _HubEntry(
      type: 'sku-carton-qty-update',
      label: l10n.importSkuCartonLabel,
      subtitle: l10n.importSkuCartonSubtitle,
      icon: Icons.inventory_outlined,
      avatarBg: const Color(0xFFFEF0E8),
      iconColor: const Color(0xFFE87040),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = _buildEntries(l10n);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: Icon(Icons.arrow_back_ios,
                            size: 18, color: Color(0xFF1A1A2E)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.importTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 12),
              child: Text(
                l10n.importSelectType,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E9A),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: entries.map((e) => _HubTile(entry: e)).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 12),
              child: Text(
                l10n.importRecordsTab,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E9A),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ImportCard(
                avatarBg: const Color(0xFFF5F4F2),
                icon: Icons.history,
                iconColor: const Color(0xFFB5B5C0),
                label: l10n.importHistoryTab,
                subtitle: l10n.importHistoryTitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _ImportLogsScreen()),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HubEntry {
  final String type;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color avatarBg;
  final Color iconColor;
  const _HubEntry({
    required this.type,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.avatarBg,
    required this.iconColor,
  });
}

class _HubTile extends StatelessWidget {
  final _HubEntry entry;
  const _HubTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return _ImportCard(
      avatarBg: entry.avatarBg,
      icon: entry.icon,
      iconColor: entry.iconColor,
      label: entry.label,
      subtitle: entry.subtitle,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _ImportDetailScreen(type: entry.type)),
      ),
    );
  }
}

class _ImportCard extends StatelessWidget {
  final Color avatarBg;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ImportCard({
    required this.avatarBg,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 76,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: avatarBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A2E),
                            )),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB5B5C0),
                            )),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: Color(0xFFB5B5C0)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Detail screen (wraps _ImportTab for a single type) ──────────────────────

class _ImportDetailScreen extends StatelessWidget {
  final String type;
  const _ImportDetailScreen({required this.type});

  Map<String, ({
    String title,
    String description,
    List<_ColDef> columns,
    List<String> notes,
  })> _buildConfigs(AppLocalizations l10n) => {
    'skus': (
      title: l10n.importSkuMasterLabel,
      description: '用于批量新增或更新 SKU 基础资料。\n已存在的 SKU 将被更新（upsert），不会重复创建。',
      columns: const [
        _ColDef('sku_code', _ColReq.required, 'SKU 编码，全大写'),
        _ColDef('name', _ColReq.optional, '商品名称'),
        _ColDef('barcode', _ColReq.optional, '条形码（请将 Excel 列格式设为文本，防止科学计数法）'),
        _ColDef('default_carton_qty', _ColReq.optional, '默认箱规（正整数），供库存导入时参考'),
        _ColDef('status', _ColReq.optional, 'active（在用）或 inactive（停用），默认 active'),
      ],
      notes: const [
        '条形码注意：在 Excel 中请将条形码列格式设为【文本】后再填入数据，'
            '否则 Excel 会将长数字转为科学计数法（如 1.23E+12）导致数据损坏。',
      ],
    ),
    'locations': (
      title: l10n.importLocationMasterLabel,
      description: '用于批量新增或更新库位基础资料。\n已存在的库位将被更新（upsert），不会重复创建。',
      columns: const [
        _ColDef('location_code', _ColReq.required, '库位编码，全大写'),
        _ColDef('description', _ColReq.optional, '库位描述'),
        _ColDef('status', _ColReq.optional, 'active（在用）或 inactive（停用），默认 active'),
      ],
      notes: const [],
    ),
    'inventory': (
      title: l10n.importInventoryLabel,
      description: '用于批量录入库存数据。\nSKU 和库位必须已存在（请先完成主档导入）。\n已有记录将被替换（upsert），不会累加。',
      columns: const [
        _ColDef('sku_code', _ColReq.required, 'SKU 编码'),
        _ColDef('location_code', _ColReq.required, '库位编码'),
        _ColDef('boxes', _ColReq.optional, '箱数，需与 carton_qty 同时填写'),
        _ColDef('carton_qty', _ColReq.optional, '每箱件数，需与 boxes 同时填写'),
        _ColDef('total_qty', _ColReq.optional, '总件数，仅填此项时按总件数导入'),
        _ColDef('stock_status', _ColReq.optional, 'confirmed / pending_count / temporary，默认 confirmed'),
        _ColDef('note', _ColReq.optional, '备注'),
      ],
      notes: const [
        '数量规则：填写 boxes+carton_qty（按箱规）或 total_qty（按总件数）。\n'
            '若数量字段均为空，系统将创建"待补充数量"记录，不报错。',
        '多箱规：同一 SKU+库位 可在文件中出现多行（不同箱规），系统自动合并为多箱规记录。',
      ],
    ),
    'sku-barcode-update': (
      title: l10n.importSkuBarcodeLabel,
      description: '仅更新已有 SKU 的条形码字段，不影响其他字段。\nSKU 不存在时报错；条形码无变化时跳过。',
      columns: const [
        _ColDef('sku_code', _ColReq.required, 'SKU 编码，必须已存在'),
        _ColDef('barcode', _ColReq.required, '新条形码（请将 Excel 列格式设为文本）'),
      ],
      notes: const [],
    ),
    'sku-carton-qty-update': (
      title: l10n.importSkuCartonLabel,
      description: '仅更新已有 SKU 的默认箱规（default_carton_qty）字段，不影响其他字段。\nSKU 不存在时报错；箱规无变化时跳过。',
      columns: const [
        _ColDef('sku_code', _ColReq.required, 'SKU 编码，必须已存在'),
        _ColDef('default_carton_qty', _ColReq.required, '新箱规，正整数'),
      ],
      notes: const [],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configs = _buildConfigs(l10n);
    final cfg = configs[type]!;
    return Scaffold(
      appBar: AppBar(title: Text(cfg.title)),
      body: _ImportTab(
        type: type,
        title: cfg.title,
        description: cfg.description,
        columns: cfg.columns,
        notes: cfg.notes,
      ),
    );
  }
}

// ─── Logs screen ──────────────────────────────────────────────────────────────

class _ImportLogsScreen extends StatelessWidget {
  const _ImportLogsScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.importHistoryTitle)),
      body: const _ImportLogsTab(),
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

class _ImportTabState extends State<_ImportTab> {
  final _service = ImportService();

  _Phase _phase = _Phase.idle;
  ImportPreview? _preview;
  ImportResult? _result;
  String? _error;

  // Hold the file bytes/name across the two steps
  List<int>? _pendingBytes;
  String? _pendingFilename;


  // ── Step 1: pick file and validate ──────────────────────────────────────

  Future<void> _pickAndValidate() async {
    final l10n = AppLocalizations.of(context)!;
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
        case 'sku-barcode-update':
          preview = await _service.validateSkuBarcodeUpdate(file.bytes!, file.name);
        case 'sku-carton-qty-update':
          preview = await _service.validateSkuCartonQtyUpdate(file.bytes!, file.name);
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
        _error = msg is List ? msg.join(', ') : (msg ?? l10n.importValidationFailed);
        _phase = _Phase.idle;
      });
    } catch (e) {
      setState(() {
        _error = l10n.importValidationError(e.toString());
        _phase = _Phase.idle;
      });
    }
  }

  // ── Step 2: confirm and import ───────────────────────────────────────────

  Future<void> _confirmImport() async {
    if (_pendingBytes == null || _pendingFilename == null) return;
    final l10n = AppLocalizations.of(context)!;

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
          result = await _service.importLocations(_pendingBytes!, _pendingFilename!);
        case 'inventory':
          result = await _service.importInventory(_pendingBytes!, _pendingFilename!);
        case 'sku-barcode-update':
          result = await _service.importSkuBarcodeUpdate(_pendingBytes!, _pendingFilename!);
        case 'sku-carton-qty-update':
          result = await _service.importSkuCartonQtyUpdate(_pendingBytes!, _pendingFilename!);
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
        _error = msg is List ? msg.join(', ') : (msg ?? l10n.importFailed);
        _phase = _Phase.preview; // stay on preview so user can retry
      });
    } catch (e) {
      setState(() {
        _error = l10n.importError(e.toString());
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
    final l10n = AppLocalizations.of(context)!;
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
                Text(l10n.importTemplateColumns,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
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
        _buildActionRow(l10n),

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

  Widget _buildActionRow(AppLocalizations l10n) {
    final busy = _phase == _Phase.validating || _phase == _Phase.importing;

    if (_phase == _Phase.preview) {
      // Two buttons: re-select file + confirm import
      return Row(children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.arrow_back, size: 16),
          label: Text(l10n.importReselect),
          onPressed: _reset,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: Text(_preview!.hasValidRows
                ? l10n.importConfirm(_preview!.willCreate + _preview!.willUpdate)
                : l10n.importNoData),
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
            label: Text(l10n.importReimport),
            onPressed: _reset,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.download_outlined, size: 18),
            label: Text(l10n.importDownloadTemplate),
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
          label: Text(l10n.importDownloadTemplate),
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
              ? l10n.importValidating
              : _phase == _Phase.importing
                  ? l10n.importImporting
                  : l10n.importSelectFile),
          onPressed: busy ? null : _pickAndValidate,
        ),
      ),
    ]);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _colTable(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          children: [_th(l10n.importColName), _th(l10n.importColRequired), _th(l10n.importColDesc)],
        ),
        ...widget.columns.map((c) => TableRow(children: [
              _td(c.name, mono: true, color: primary),
              _tdReq(c.req, l10n),
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

  Widget _tdReq(_ColReq req, AppLocalizations l10n) {
    final (label, color) = switch (req) {
      _ColReq.required => (l10n.importReqRequired, Colors.red.shade600),
      _ColReq.eitherA => (l10n.importReqEitherA, Colors.deepOrange.shade600),
      _ColReq.eitherB => (l10n.importReqEitherB, Colors.deepOrange.shade600),
      _ColReq.optional => (l10n.importReqOptional, Colors.grey.shade500),
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
    final l10n = AppLocalizations.of(context)!;
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
                          ? (hasValid ? l10n.importValidationOkWithErrors : l10n.importValidationAllErrors)
                          : l10n.importValidationPassed,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hasErrors
                              ? (hasValid
                                  ? Colors.orange.shade800
                                  : Colors.red.shade700)
                              : Colors.green.shade700),
                    ),
                    Text(l10n.importFilename(filename),
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
              _stat(l10n.importStatTotal, preview.total, Colors.grey.shade700),
              _stat(l10n.importStatCreate, preview.willCreate, Colors.green.shade700),
              _stat(l10n.importStatUpdate, preview.willUpdate, Colors.blue.shade700),
              if (preview.willSkip > 0)
                _stat(l10n.importStatSkip, preview.willSkip, Colors.orange.shade700),
              if (preview.hasErrors)
                _stat(l10n.importStatError, preview.errorCount, Colors.red.shade700),
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
                  Text(l10n.importErrorDetails,
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
                                Text(l10n.importRowLabel(r.row),
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
                        l10n.importMoreErrors(preview.errorCount - 20),
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
                  Text(l10n.importPreviewData,
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
                                    r.isCreate ? l10n.importCreate : l10n.importUpdate,
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
                        l10n.importMoreRows(preview.willCreate + preview.willUpdate - 30),
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
    final l10n = AppLocalizations.of(context)!;
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
                allOk ? l10n.importDoneTitle : l10n.importDoneWithErrors,
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
              _stat(l10n.importResultTotal, result.total, Colors.grey.shade700),
              _stat(l10n.importResultCreate, result.created, Colors.green.shade700),
              _stat(l10n.importResultUpdate, result.updated, Colors.blue.shade700),
              if (result.skipped > 0)
                _stat(l10n.importResultSkip, result.skipped, Colors.orange.shade700),
              if (result.hasErrors)
                _stat(l10n.importResultError, result.errors.length, Colors.red.shade700),
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
                  Text(l10n.importRowErrorDetails,
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
                              Text(l10n.importRowLabel(e.row),
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
                        l10n.importMoreRowErrors(result.errors.length - 20),
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

class _ImportLogsTabState extends State<_ImportLogsTab> {
  final _service = ImportService();

  List<ImportLogRecord> _records = [];
  int _total = 0;
  int _page = 1;
  bool _loading = false;
  String? _error;
  String? _filterType;

  List<(String?, String)> _buildTypeOptions(AppLocalizations l10n) => [
    (null, l10n.importFilterAll),
    ('skus', l10n.importFilterSku),
    ('locations', l10n.importFilterLocation),
    ('inventory', l10n.importFilterInventory),
    ('sku-barcode-update', l10n.importFilterBarcodeUpdate),
    ('sku-carton-qty-update', l10n.importFilterCartonUpdate),
  ];

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
    final l10n = AppLocalizations.of(context)!;
    final typeOptions = _buildTypeOptions(l10n);
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
                    children: typeOptions.map((opt) {
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
                tooltip: l10n.importRefresh,
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
              child: Text(l10n.importHistoryTotal(_total),
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
                              child: Text(l10n.errorRetry)),
                        ],
                      ),
                    )
                  : _records.isEmpty
                      ? Center(
                          child: Text(l10n.importHistoryEmpty,
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
                                      child: Text(l10n.importHistoryLoadMore),
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

class _LogCard extends StatefulWidget {
  final ImportLogRecord record;
  const _LogCard({required this.record});

  @override
  State<_LogCard> createState() => _LogCardState();
}

class _LogCardState extends State<_LogCard> {
  final _service = ImportService();
  bool _exporting = false;

  Future<void> _exportLog() async {
    setState(() => _exporting = true);
    // ignore: avoid_print
    print('[exportLog] record.id="${widget.record.id}" type=${widget.record.importType}');
    try {
      await _service.exportLog(widget.record);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importExportFailed(e.toString())), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final record = widget.record;
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
      statusLabel = l10n.importStatusSuccess;
      statusIcon = Icons.check_circle_outline;
    } else if (hasErrors && record.created + record.updated > 0) {
      borderColor = Colors.orange.shade200;
      bgColor = Colors.orange.shade50;
      statusColor = Colors.orange.shade700;
      statusLabel = l10n.importStatusPartial;
      statusIcon = Icons.warning_amber_outlined;
    } else if (hasErrors && record.created + record.updated == 0) {
      borderColor = Colors.red.shade200;
      bgColor = Colors.red.shade50;
      statusColor = Colors.red.shade600;
      statusLabel = l10n.importStatusAllFailed;
      statusIcon = Icons.error_outline;
    } else {
      borderColor = Colors.blue.shade200;
      bgColor = Colors.blue.shade50;
      statusColor = Colors.blue.shade700;
      statusLabel = l10n.importStatusSkipped;
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
                color: statusColor.withValues(alpha: 0.12),
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
                    _stat(l10n.importHistoryStatTotal, record.total, Colors.grey.shade700),
                    _stat(l10n.importHistoryStatCreate, record.created, Colors.green.shade700),
                    _stat(l10n.importHistoryStatUpdate, record.updated, Colors.blue.shade700),
                    if (record.skipped > 0)
                      _stat(l10n.importHistoryStatSkip, record.skipped, Colors.orange.shade700),
                    if (hasErrors)
                      _stat(l10n.importHistoryStatError, record.errors.length, Colors.red.shade600),
                  ],
                ),
                if (hasErrors) ...[
                  const SizedBox(height: 10),
                  Text(l10n.importHistoryRowErrors,
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
                            Text(l10n.importRowLabel(e.row),
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
                    Text(l10n.importHistoryMoreErrors(record.errors.length - 20),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: _exporting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.download_outlined, size: 16),
                    label: Text(_exporting ? l10n.importExporting : l10n.importExportDetail),
                    onPressed: _exporting ? null : _exportLog,
                  ),
                ),
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
