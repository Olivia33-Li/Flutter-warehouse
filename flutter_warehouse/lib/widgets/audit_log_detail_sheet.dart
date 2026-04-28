import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/change_record.dart';
import '../l10n/app_localizations.dart';

class AuditLogDetailSheet extends StatelessWidget {
  final ChangeRecord record;
  final (Color, Color, IconData) style;
  final String label;

  const AuditLogDetailSheet({
    super.key,
    required this.record,
    required this.style,
    required this.label,
  });

  // ── Static helpers ──────────────────────────────────────────────────────────
  static (Color, Color, IconData) badgeStyle(ChangeRecord r) {
    final ba = r.businessAction ?? r.action;
    switch (ba) {
      case '入库':
        return (Colors.green.shade600, Colors.green.shade50, Icons.add_box_outlined);
      case '出库':
        return (Colors.orange.shade700, Colors.orange.shade50, Icons.outbox_outlined);
      case '调整':
        return (Colors.blue.shade600, Colors.blue.shade50, Icons.tune);
      case '录入':
        return (Colors.teal.shade600, Colors.teal.shade50, Icons.edit_note);
      case '删除库存':
        return (Colors.red.shade600, Colors.red.shade50, Icons.delete_outline);
      case '结构修改':
        return (Colors.purple.shade600, Colors.purple.shade50, Icons.construction_outlined);
      case '批量转移':
      case '批量转入':
        return (Colors.indigo.shade600, Colors.indigo.shade50, Icons.swap_horiz);
      case '批量复制':
      case '批量复制进入':
        return (Colors.amber.shade700, Colors.amber.shade50, Icons.copy_outlined);
      case '新建库位':
        return (Colors.teal.shade600, Colors.teal.shade50, Icons.add_location_alt_outlined);
      case '编辑库位':
        return (Colors.blueGrey.shade600, Colors.blueGrey.shade50, Icons.edit_location_alt_outlined);
      case '删除库位':
        return (Colors.red.shade600, Colors.red.shade50, Icons.wrong_location_outlined);
      case '标记已检查':
        return (Colors.green.shade600, Colors.green.shade50, Icons.check_circle_outline);
      case '取消已检查':
        return (Colors.grey.shade600, Colors.grey.shade50, Icons.cancel_outlined);
      case '新建SKU':
        return (Colors.teal.shade600, Colors.teal.shade50, Icons.add_circle_outline);
      case '编辑SKU':
        return (Colors.blueGrey.shade600, Colors.blueGrey.shade50, Icons.edit_outlined);
      case '删除SKU':
        return (Colors.red.shade600, Colors.red.shade50, Icons.remove_circle_outline);
      case 'create':
        return (Colors.green.shade600, Colors.green.shade50, Icons.add_circle_outline);
      case 'update':
        return (Colors.blue.shade600, Colors.blue.shade50, Icons.edit_outlined);
      case 'delete':
        return (Colors.red.shade600, Colors.red.shade50, Icons.delete_outline);
      default:
        return (Colors.grey.shade600, Colors.grey.shade50, Icons.history);
    }
  }

  static String translateAction(String? ba, AppLocalizations l10n) {
    if (ba == null) return '';
    switch (ba) {
      case '入库': return l10n.auditBusinessActionStockIn;
      case '出库': return l10n.auditBusinessActionStockOut;
      case '调整': return l10n.auditBusinessActionAdjust;
      case '录入': return l10n.auditBusinessActionEntry;
      case '删除库存': return l10n.auditBusinessActionDeleteStock;
      case '结构修改': return l10n.auditBusinessActionStructure;
      case '批量转移': return l10n.auditBusinessActionTransfer;
      case '批量转入': return l10n.auditBusinessActionTransferIn;
      case '批量复制': return l10n.auditBusinessActionCopy;
      case '批量复制进入': return l10n.auditBusinessActionCopyIn;
      case '新建库位': return l10n.auditBusinessActionNewLocation;
      case '编辑库位': return l10n.auditBusinessActionEditLocation;
      case '删除库位': return l10n.auditBusinessActionDeleteLocation;
      case '标记已检查': return l10n.auditBusinessActionMarkChecked;
      case '取消已检查': return l10n.auditBusinessActionUnmarkChecked;
      case '新建SKU': return l10n.auditBusinessActionNewSku;
      case '编辑SKU': return l10n.auditBusinessActionEditSku;
      case '删除SKU': return l10n.auditBusinessActionDeleteSku;
      default: return ba;
    }
  }

  static String translateEntity(String entity, AppLocalizations l10n) {
    switch (entity.toLowerCase()) {
      case 'sku': return 'SKU';
      case '库存':
      case 'inventory': return l10n.historyEntityInventory;
      case '库位':
      case 'location': return l10n.historyEntityLocation;
      default: return entity;
    }
  }

  static String? localizedDescription(
      Map<String, dynamic>? d, String? ba, AppLocalizations l10n) {
    if (d == null || ba == null) return null;
    final pcs = l10n.unitPiece;
    final skuCode = d['skuCode']?.toString() ?? '';
    final locCode = d['locationCode']?.toString() ?? '';
    switch (ba) {
      case '入库':
        if (d['boxesOnlyMode'] == true) {
          return '$skuCode @ $locCode · +${d['boxes'] ?? 0} ${l10n.invDetailBoxesSuffix}';
        }
        return '$skuCode @ $locCode · +${d['addedQty'] ?? 0}$pcs';
      case '出库':
        final unconfiguredOut = (d['unconfiguredCartons'] as num?) ?? 0;
        if (unconfiguredOut > 0) {
          return '$skuCode @ $locCode · -$unconfiguredOut ${l10n.unitBox}';
        }
        return '$skuCode @ $locCode · -${d['reducedQty'] ?? 0}$pcs';
      case '调整':
        final bQty   = (d['beforeQty']  as num?) ?? 0;
        final aQty   = (d['afterQty']   as num?) ?? 0;
        final bBoxes = (d['beforeBoxes'] as num?) ?? 0;
        final aBoxes = (d['afterBoxes']  as num?) ?? 0;
        final ctn    = l10n.unitBox;
        // boxesOnly records have quantity=0; fall back to box count for display
        final bDisplay = bQty > 0 ? '$bQty$pcs' : (bBoxes > 0 ? '$bBoxes $ctn' : '0$pcs');
        final aDisplay = aQty > 0 ? '$aQty$pcs' : (aBoxes > 0 ? '$aBoxes $ctn' : '0$pcs');
        return '$skuCode @ $locCode · $bDisplay→$aDisplay';
      case '录入':
        return '$skuCode @ $locCode · ${d['quantity'] ?? 0}$pcs';
      default:
        return null;
    }
  }

  /// Cleans a raw backend-generated (possibly Chinese) description:
  /// 1. Takes only the first line (strips any trailing Chinese audit detail)
  /// 2. Strips Chinese action prefix up to the first ': '
  /// 3. Converts common Chinese quantity patterns to English
  static String cleanDesc(String raw) {
    // Step 1: first line only (backend sometimes appends a Chinese detail on line 2)
    String s = raw.split('\n').first.trim();
    // Step 2: strip Chinese action prefix, e.g. "出库: " or "箱规调整: "
    final colonIdx = s.indexOf(': ');
    if (colonIdx != -1) s = s.substring(colonIdx + 2).trim();
    // Step 3: convert Chinese quantity/label patterns to English
    // e.g. "-3箱×144件/箱=-432件" → "-3 cartons × 144 pcs/carton = -432 pcs"
    s = s.replaceAllMapped(
      RegExp(r'(-?\d+)箱×(\d+)件/箱=(-?\d+)件'),
      (m) => '${m[1]} cartons × ${m[2]} pcs/carton = ${m[3]} pcs',
    );
    // e.g. "+6件" or "-100件" → "+6 pcs" / "-100 pcs"
    s = s.replaceAllMapped(
      RegExp(r'([+-]?\d+)件'),
      (m) => '${m[1]} pcs',
    );
    // e.g. "12箱" standalone → "12 cartons"
    s = s.replaceAllMapped(
      RegExp(r'(\d+)箱'),
      (m) => '${m[1]} cartons',
    );
    // label translations
    s = s.replaceAll('（无箱规）', '(no carton qty)');
    s = s.replaceAll('无箱规', 'no carton qty');
    s = s.replaceAll('调前', 'Before');
    s = s.replaceAll('调后', 'After');
    s = s.replaceAll('原因', 'Reason');
    return s.trim();
  }

  static String badgeLabel(ChangeRecord r, AppLocalizations l10n) {
    if (r.businessAction != null) return translateAction(r.businessAction, l10n);
    switch (r.action) {
      case 'create': return l10n.badgeActionCreate;
      case 'update': return l10n.badgeActionUpdate;
      case 'delete': return l10n.badgeActionDelete;
      default: return r.action;
    }
  }

  static void show(BuildContext context, ChangeRecord record) {
    final style = badgeStyle(record);
    final label = badgeLabel(record, AppLocalizations.of(context)!);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AuditLogDetailSheet(
        record: record,
        style: style,
        label: label,
      ),
    );
  }

  static String _formatFull(DateTime dt) =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(dt.toLocal());

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final (fg, bg, icon) = style;
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Column(
        children: [
          // ── Handle ───────────────────────────────────────────────────
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          // ── Header ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 24, color: fg),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black87)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              translateEntity(record.entity, l10n),
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: fg),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 13, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Text(record.userName,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500)),
                          const SizedBox(width: 10),
                          Icon(Icons.access_time,
                              size: 13, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Text(_formatFull(record.createdAt),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.grey.shade100),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: _buildBody(fg, bg, l10n),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBody(Color fg, Color bg, AppLocalizations l10n) {
    final d = record.details;
    final ba = record.businessAction;
    final widgets = <Widget>[];

    widgets.add(_sectionCard(
      title: l10n.auditBasicInfo,
      icon: Icons.info_outline,
      children: [
        _row(l10n.auditActionType, label),
        _row(l10n.auditEntity, translateEntity(record.entity, l10n)),
        if (record.entityId != null) _row(l10n.auditEntityId, record.entityId!),
        _row(l10n.auditOperator, record.userName),
        _row(l10n.auditTime, _formatFull(record.createdAt)),
      ],
    ));
    widgets.add(const SizedBox(height: 12));

    final descText = localizedDescription(d, ba, l10n) ??
        (l10n.localeName == 'en' ? cleanDesc(record.description) : record.description);
    widgets.add(_sectionCard(
      title: l10n.auditDescription,
      icon: Icons.description_outlined,
      children: [
        Text(descText,
            style: const TextStyle(fontSize: 13, height: 1.5)),
      ],
    ));
    widgets.add(const SizedBox(height: 12));

    if (d != null && ba != null) {
      final typeWidgets = _buildTypeDetail(d, ba, fg, bg, l10n);
      if (typeWidgets.isNotEmpty) {
        widgets.addAll(typeWidgets);
        widgets.add(const SizedBox(height: 12));
      }
    }

    if (record.changes != null && record.changes!.isNotEmpty) {
      widgets.add(_sectionCard(
        title: l10n.auditFieldChanges,
        icon: Icons.compare_arrows,
        children: record.changes!.entries.map((e) {
          final before = e.value['before']?.toString() ?? l10n.auditNone;
          final after = e.value['after']?.toString() ?? l10n.auditNone;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80,
                  child: Text(e.key,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 13)),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Text(before,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward,
                            size: 14, color: Colors.grey),
                      ),
                      Text(after,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ));
      widgets.add(const SizedBox(height: 12));
    }

    return widgets;
  }

  // ── Type-specific sections ──────────────────────────────────────────────────
  List<Widget> _buildTypeDetail(
      Map<String, dynamic> d, String ba, Color fg, Color bg, AppLocalizations l10n) {
    switch (ba) {
      case '入库':
        return _buildStockInDetail(d, fg, bg, l10n);
      case '出库':
        return _buildStockOutDetail(d, fg, bg, l10n);
      case '调整':
        return _buildAdjustDetail(d, fg, bg, l10n);
      case '录入':
        return _buildCreateDetail(d, fg, bg, l10n);
      case '删除库存':
        return _buildDeleteInventoryDetail(d, l10n);
      case '结构修改':
        return _buildStructureDetail(d, fg, bg, l10n);
      case '批量转移':
      case '批量转入':
        return _buildBatchTransferDetail(d, fg, bg, l10n);
      case '批量复制':
      case '批量复制进入':
        return _buildBatchCopyDetail(d, fg, bg, l10n);
      case '标记已检查':
      case '取消已检查':
        return _buildCheckDetail(d, ba, fg, bg, l10n);
      case '新建库位':
      case '编辑库位':
      case '删除库位':
        return _buildLocationDetail(d, ba, l10n);
      default:
        return [];
    }
  }

  // ── 入库 ─────────────────────────────────────────────────────────────────────
  List<Widget> _buildStockInDetail(
      Map<String, dynamic> d, Color fg, Color bg, AppLocalizations l10n) {
    final isBoxesOnly = d['boxesOnlyMode'] == true;
    final boxes = (d['boxes'] ?? 0) as num;
    final upb = (d['unitsPerBox'] ?? 1) as num;
    final addedQty = (d['addedQty'] ?? boxes * upb) as num;
    // beforeQty/beforeBoxes now captured by backend; fall back to 0 for old records
    final beforeQty   = (d['beforeQty']   as num?) ?? 0;
    final beforeBoxes = (d['beforeBoxes'] as num?) ?? 0;
    final afterQty = (d['afterQty'] as num?) ?? beforeQty + addedQty;
    // For boxesOnly stockIn: use box counts for before/after display
    final addedBoxes = (d['unconfiguredCartons'] as num?) ?? boxes;

    return [
      _sectionCard(
        title: l10n.auditStockInTitle,
        icon: Icons.add_box_outlined,
        children: [
          _row('SKU', d['skuCode']),
          _row(l10n.auditLocation, d['locationCode']),
          const SizedBox(height: 8),
          if (isBoxesOnly)
            _qtyHighlight('+${boxes.toInt()} ${l10n.invDetailBoxesSuffix}  (${l10n.invDetailCartonTBD.trim()})', Colors.green.shade600)
          else
            _configsBlock(
              [{'boxes': boxes, 'unitsPerBox': upb}],
              highlightColor: Colors.green.shade600,
              l10n: l10n,
            ),
        ],
      ),
      const SizedBox(height: 12),
      _sectionCard(
        title: l10n.auditBeforeAfterChange,
        icon: Icons.show_chart,
        children: [
          if (isBoxesOnly)
            _inventoryChangeWidget(
              beforeLabel: '$beforeBoxes ${l10n.unitBox}',
              changeLabel: '+$addedBoxes ${l10n.unitBox}',
              afterLabel: '${(beforeBoxes + addedBoxes).toInt()} ${l10n.unitBox}',
              changeColor: Colors.green.shade600,
              l10n: l10n,
            )
          else
            _inventoryChangeWidget(
              beforeLabel: l10n.auditQtyPcs(beforeQty.toInt()),
              changeLabel: l10n.auditQtyAdded(addedQty.toInt()),
              afterLabel: l10n.auditQtyPcs(afterQty.toInt()),
              changeColor: Colors.green.shade600,
              l10n: l10n,
            ),
        ],
      ),
    ];
  }

  // ── 出库 ─────────────────────────────────────────────────────────────────────
  List<Widget> _buildStockOutDetail(
      Map<String, dynamic> d, Color fg, Color bg, AppLocalizations l10n) {
    final unconfiguredOut = (d['unconfiguredCartons'] as num?) ?? 0;
    final ctn = l10n.unitBox;

    // ── boxesOnly (unconfiguredCartons) stockOut ──────────────────────────────
    if (unconfiguredOut > 0) {
      final beforeBoxes = (d['beforeBoxes'] as num?) ?? unconfiguredOut;
      final afterBoxes  = (d['afterBoxes']  as num?) ?? (beforeBoxes - unconfiguredOut);
      return [
        _sectionCard(
          title: l10n.auditStockOutTitle,
          icon: Icons.outbox_outlined,
          children: [
            _row('SKU', d['skuCode']),
            _row(l10n.auditLocation, d['locationCode']),
            const SizedBox(height: 8),
            _qtyHighlight('-$unconfiguredOut $ctn', Colors.orange.shade700),
          ],
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: l10n.auditBeforeAfterChange,
          icon: Icons.show_chart,
          children: [
            _beforeAfterWidget(
              '$beforeBoxes $ctn',
              '$afterBoxes $ctn',
              l10n,
            ),
          ],
        ),
      ];
    }

    // ── pcs / carton-spec stockOut ────────────────────────────────────────────
    final reduced   = (d['reducedQty']   ?? 0) as num;
    final remaining = (d['remainingQty'] as num?) ?? 0;
    // Use beforeQty from details when available (more accurate than reduced+remaining for mixed records)
    final beforeQty = (d['beforeQty'] as num?) ?? reduced + remaining;

    return [
      _sectionCard(
        title: l10n.auditStockOutTitle,
        icon: Icons.outbox_outlined,
        children: [
          _row('SKU', d['skuCode']),
          _row(l10n.auditLocation, d['locationCode']),
          const SizedBox(height: 8),
          _qtyHighlight(l10n.auditQtyReduced(reduced.toInt()), Colors.orange.shade700),
        ],
      ),
      const SizedBox(height: 12),
      _sectionCard(
        title: l10n.auditBeforeAfterChange,
        icon: Icons.show_chart,
        children: [
          _inventoryChangeWidget(
            beforeLabel: l10n.auditQtyPcs(beforeQty.toInt()),
            changeLabel: l10n.auditQtyReduced(reduced.toInt()),
            afterLabel: l10n.auditQtyPcs(remaining.toInt()),
            changeColor: Colors.orange.shade700,
            l10n: l10n,
          ),
        ],
      ),
    ];
  }

  // ── 调整 ─────────────────────────────────────────────────────────────────────
  List<Widget> _buildAdjustDetail(
      Map<String, dynamic> d, Color fg, Color bg, AppLocalizations l10n) {
    final beforeQty   = (d['beforeQty']   as num?) ?? 0;
    final afterQty    = (d['afterQty']    as num?) ?? 0;
    final beforeBoxes = (d['beforeBoxes'] as num?) ?? 0;
    final afterBoxes  = (d['afterBoxes']  as num?) ?? 0;
    final mode = d['mode'] == 'config' ? l10n.auditAdjustModeConfig : l10n.auditAdjustModeQty;
    final note = d['note']?.toString();
    final ctn = l10n.unitBox;
    final pcs = l10n.unitPiece;

    // For boxesOnly records quantity is always 0; use box count for display
    final beforeLabel = beforeQty > 0
        ? '$beforeQty $pcs'
        : (beforeBoxes > 0 ? '$beforeBoxes $ctn' : '0 $pcs');
    final afterLabel = afterQty > 0
        ? '$afterQty $pcs'
        : (afterBoxes > 0 ? '$afterBoxes $ctn' : '0 $pcs');

    return [
      _sectionCard(
        title: l10n.auditAdjustTitle,
        icon: Icons.tune,
        children: [
          _row('SKU', d['skuCode']),
          _row(l10n.auditLocation, d['locationCode']),
          _row(l10n.auditAdjustMode, mode),
          if (note != null && note.isNotEmpty) _row(l10n.auditNote, note),
        ],
      ),
      const SizedBox(height: 12),
      _sectionCard(
        title: l10n.auditBeforeAfterChange,
        icon: Icons.show_chart,
        children: [
          _beforeAfterWidget(beforeLabel, afterLabel, l10n),
        ],
      ),
    ];
  }

  // ── 录入 ─────────────────────────────────────────────────────────────────────
  List<Widget> _buildCreateDetail(
      Map<String, dynamic> d, Color fg, Color bg, AppLocalizations l10n) {
    final boxes = (d['boxes'] ?? 0) as num;
    final upb = (d['unitsPerBox'] ?? 1) as num;
    final quantity = (d['quantity'] ?? boxes * upb) as num;

    return [
      _sectionCard(
        title: l10n.auditEntryTitle,
        icon: Icons.edit_note,
        children: [
          _row('SKU', d['skuCode']),
          _row(l10n.auditLocation, d['locationCode']),
          const SizedBox(height: 8),
          _configsBlock(
            [{'boxes': boxes, 'unitsPerBox': upb}],
            highlightColor: Colors.teal.shade600,
            l10n: l10n,
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              l10n.auditFirstEntry(quantity.toInt()),
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.teal.shade700,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    ];
  }

  // ── 删除库存 ─────────────────────────────────────────────────────────────────
  List<Widget> _buildDeleteInventoryDetail(Map<String, dynamic> d, AppLocalizations l10n) {
    final quantity = (d['quantity'] ?? 0) as num;
    final configs = _toMapList(d['configurations']);

    return [
      _sectionCard(
        title: l10n.auditDeleteStockTitle,
        icon: Icons.delete_outline,
        children: [
          _row('SKU', d['skuCode']),
          _row(l10n.auditLocation, d['locationCode']),
          const SizedBox(height: 8),
          if (configs.isNotEmpty)
            _configsBlock(configs, highlightColor: Colors.red.shade600, l10n: l10n)
          else
            _qtyHighlight(l10n.auditQtyPcs(quantity.toInt()), Colors.red.shade600),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_outlined,
                    size: 14, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.auditDeletedNotice,
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  // ── 结构修改 ─────────────────────────────────────────────────────────────────
  List<Widget> _buildStructureDetail(
      Map<String, dynamic> d, Color fg, Color bg, AppLocalizations l10n) {
    final beforeBoxes = d['beforeBoxes'] as num?;
    final beforeUpb = d['beforeUnitsPerBox'] as num?;
    final afterBoxes = d['afterBoxes'] as num?;
    final afterUpb = d['afterUnitsPerBox'] as num?;
    final beforeQty = d['beforeQty'] as num?;
    final afterQty = d['afterQty'] as num?;
    final beforeConfigs = _toMapList(d['beforeConfigurations']);
    final afterConfigs = _toMapList(d['afterConfigurations']);

    final effectiveBefore = beforeConfigs.isNotEmpty
        ? beforeConfigs
        : (beforeBoxes != null && beforeUpb != null
            ? [
                {'boxes': beforeBoxes, 'unitsPerBox': beforeUpb}
              ]
            : <Map<String, dynamic>>[]);
    final effectiveAfter = afterConfigs.isNotEmpty
        ? afterConfigs
        : (afterBoxes != null && afterUpb != null
            ? [
                {'boxes': afterBoxes, 'unitsPerBox': afterUpb}
              ]
            : <Map<String, dynamic>>[]);

    return [
      _sectionCard(
        title: l10n.auditStructureTitle,
        icon: Icons.construction_outlined,
        children: [
          _row('SKU', d['skuCode']),
          _row(l10n.auditLocation, d['locationCode']),
        ],
      ),
      if (effectiveBefore.isNotEmpty || effectiveAfter.isNotEmpty) ...[
        const SizedBox(height: 12),
        _sectionCard(
          title: l10n.auditBeforeAfterChange,
          icon: Icons.show_chart,
          children: [
            _configsBeforeAfterWidget(effectiveBefore, effectiveAfter, l10n),
          ],
        ),
      ] else if (beforeQty != null && afterQty != null) ...[
        const SizedBox(height: 12),
        _sectionCard(
          title: l10n.auditBeforeAfterChange,
          icon: Icons.show_chart,
          children: [
            _beforeAfterWidget(
              l10n.auditQtyPcs(beforeQty.toInt()),
              l10n.auditQtyPcs(afterQty.toInt()),
              l10n,
            ),
          ],
        ),
      ],
    ];
  }

  // ── 批量转移 ─────────────────────────────────────────────────────────────────
  List<Widget> _buildBatchTransferDetail(
      Map<String, dynamic> d, Color fg, Color bg, AppLocalizations l10n) {
    final movedRaw = _toMapList(d['movedDetails']);
    final mergedRaw = _toMapList(d['mergedDetails']);
    final overwrittenRaw = _toMapList(d['overwrittenDetails']);
    final moved = movedRaw.isNotEmpty
        ? movedRaw as List<dynamic>
        : _toList(d['moved']) as List<dynamic>;
    final merged = mergedRaw.isNotEmpty
        ? mergedRaw as List<dynamic>
        : _toList(d['merged']) as List<dynamic>;
    final overwritten = overwrittenRaw.isNotEmpty
        ? overwrittenRaw as List<dynamic>
        : _toList(d['overwritten']) as List<dynamic>;
    final total =
        (d['total'] as num?) ?? moved.length + merged.length + overwritten.length;

    return [
      _sectionCard(
        title: l10n.auditTransferTitle,
        icon: Icons.swap_horiz,
        children: [
          _routeBanner(d['sourceCode'] ?? '', d['targetCode'] ?? '',
              total, fg, bg,
              isTransfer: true, l10n: l10n),
          const SizedBox(height: 8),
          _row(l10n.auditSourceLocation, d['sourceCode']),
          _row(l10n.auditTargetLocation, d['targetCode']),
          _row(l10n.auditSkuTotal(total.toInt()), ''),
        ],
      ),
      const SizedBox(height: 12),
      _sectionCard(
        title: l10n.auditAffectedDetails,
        icon: Icons.list_alt_outlined,
        children: [
          if (moved.isNotEmpty) ...[
            _skuDetailGroup(l10n.auditDirectTransfer, moved, Colors.green.shade700,
                l10n.auditDirectTransferDesc, l10n),
            if (merged.isNotEmpty || overwritten.isNotEmpty)
              const SizedBox(height: 12),
          ],
          if (merged.isNotEmpty) ...[
            _skuDetailGroup(l10n.auditMerged, merged, Colors.blue.shade700,
                l10n.auditMergedDesc, l10n),
            if (overwritten.isNotEmpty) const SizedBox(height: 12),
          ],
          if (overwritten.isNotEmpty)
            _skuDetailGroup(l10n.auditOverwritten, overwritten, Colors.red.shade700,
                l10n.auditOverwrittenDesc, l10n),
        ],
      ),
      const SizedBox(height: 12),
      _sectionCard(
        title: l10n.auditImpactResult,
        icon: Icons.info_outline,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_outlined,
                    size: 15, color: Colors.amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.auditTransferDeleteNotice,
                    style: const TextStyle(fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  // ── 批量复制 ─────────────────────────────────────────────────────────────────
  List<Widget> _buildBatchCopyDetail(
      Map<String, dynamic> d, Color fg, Color bg, AppLocalizations l10n) {
    final copiedRaw = _toMapList(d['copiedDetails']);
    final stackedRaw = _toMapList(d['stackedDetails']);
    final overwrittenRaw = _toMapList(d['overwrittenDetails']);
    final copied = copiedRaw.isNotEmpty
        ? copiedRaw as List<dynamic>
        : _toList(d['copied']) as List<dynamic>;
    final stacked = stackedRaw.isNotEmpty
        ? stackedRaw as List<dynamic>
        : _toList(d['stacked']) as List<dynamic>;
    final overwritten = overwrittenRaw.isNotEmpty
        ? overwrittenRaw as List<dynamic>
        : _toList(d['overwritten']) as List<dynamic>;
    final total =
        (d['total'] as num?) ?? copied.length + stacked.length + overwritten.length;

    return [
      _sectionCard(
        title: l10n.auditCopyTitle,
        icon: Icons.copy_outlined,
        children: [
          _routeBanner(d['sourceCode'] ?? '', d['targetCode'] ?? '',
              total, fg, bg,
              isTransfer: false, l10n: l10n),
          const SizedBox(height: 8),
          _row(l10n.auditSourceLocation, d['sourceCode']),
          _row(l10n.auditTargetLocation, d['targetCode']),
          _row(l10n.auditSkuTotal(total.toInt()), ''),
          _row(l10n.auditSourceLocation, l10n.auditCopySourceUnchanged),
        ],
      ),
      const SizedBox(height: 12),
      _sectionCard(
        title: l10n.auditAffectedDetails,
        icon: Icons.list_alt_outlined,
        children: [
          if (copied.isNotEmpty) ...[
            _skuDetailGroup(l10n.auditDirectCopy, copied, Colors.green.shade700,
                l10n.auditDirectCopyDesc, l10n),
            if (stacked.isNotEmpty || overwritten.isNotEmpty)
              const SizedBox(height: 12),
          ],
          if (stacked.isNotEmpty) ...[
            _skuDetailGroup(l10n.auditStacked, stacked, Colors.blue.shade700,
                l10n.auditStackedDesc, l10n),
            if (overwritten.isNotEmpty) const SizedBox(height: 12),
          ],
          if (overwritten.isNotEmpty)
            _skuDetailGroup(l10n.auditOverwritten, overwritten, Colors.red.shade700,
                l10n.auditOverwrittenDesc, l10n),
        ],
      ),
    ];
  }

  // ── 检查状态 ─────────────────────────────────────────────────────────────────
  List<Widget> _buildCheckDetail(
      Map<String, dynamic> d, String ba, Color fg, Color bg, AppLocalizations l10n) {
    return [
      _sectionCard(
        title: l10n.auditCheckTitle,
        icon: Icons.check_circle_outline,
        children: [
          _row(l10n.auditLocation, d['locationCode']),
          _row(l10n.auditCheckedChange,
              ba == '标记已检查' ? l10n.auditMarkChecked : l10n.auditUnmarkChecked),
          if (d['checkedBy'] != null) _row(l10n.auditCheckedBy, d['checkedBy']),
          if (d['checkedAt'] != null)
            _row(
                l10n.auditCheckedAt,
                DateFormat('yyyy-MM-dd HH:mm').format(
                    DateTime.parse(d['checkedAt']).toLocal())),
        ],
      ),
    ];
  }

  // ── 库位操作 ─────────────────────────────────────────────────────────────────
  List<Widget> _buildLocationDetail(Map<String, dynamic> d, String ba, AppLocalizations l10n) {
    final iconData = ba == '新建库位'
        ? Icons.add_location_alt_outlined
        : ba == '编辑库位'
            ? Icons.edit_location_alt_outlined
            : Icons.wrong_location_outlined;
    return [
      _sectionCard(
        title: l10n.auditLocationOpTitle,
        icon: iconData,
        children: [
          _row(l10n.auditLocationCode, d['locationCode']),
          if (d['description'] != null &&
              d['description'].toString().isNotEmpty)
            _row(l10n.auditDescription2, d['description']),
        ],
      ),
    ];
  }

  // ── Shared section card ─────────────────────────────────────────────────────
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) =>
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  Icon(icon, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey.shade600)),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      );

  // ── Label-value row ─────────────────────────────────────────────────────────
  Widget _row(String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Text(label,
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(value?.toString() ?? '-',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
            ),
          ],
        ),
      );

  // ── Carton structure block: [N箱] × [M件/箱] = [X件] ───────────────────────
  Widget _configsBlock(List<dynamic> configs, {Color? highlightColor, required AppLocalizations l10n}) {
    if (configs.isEmpty) {
      return Text(l10n.auditNoStock,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12));
    }
    final color = highlightColor ?? Colors.blue.shade700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: configs.map<Widget>((c) {
        final boxes = (c['boxes'] ?? 0) as num;
        final upb = (c['unitsPerBox'] ?? 1) as num;
        final total = boxes * upb;
        return Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              _pill(l10n.auditQtyBoxes(boxes.toInt()), Colors.grey.shade600),
              Text('×',
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                      fontWeight: FontWeight.w300)),
              _pill(l10n.auditQtyPcsPerBox(upb.toInt()), Colors.grey.shade600),
              Text('=',
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                      fontWeight: FontWeight.w300)),
              _pill(l10n.auditQtyPcs(total.toInt()), color, bold: true),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Small styled pill badge ─────────────────────────────────────────────────
  Widget _pill(String text, Color color, {bool bold = false}) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w500,
                color: color)),
      );

  // ── Before/after with carton configs ───────────────────────────────────────
  Widget _configsBeforeAfterWidget(
      List<dynamic> before, List<dynamic> after, AppLocalizations l10n) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.auditBeforeLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  _configsBlock(before, l10n: l10n),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  Icon(Icons.arrow_forward,
                      color: Colors.grey.shade400, size: 20),
                  Text(l10n.auditChangeLabel,
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.auditAfterLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  _configsBlock(after,
                      highlightColor: Colors.blue.shade700, l10n: l10n),
                ],
              ),
            ),
          ],
        ),
      );

  // ── Before / after with change badge (for 入库/出库) ───────────────────────
  Widget _inventoryChangeWidget({
    required String beforeLabel,
    required String changeLabel,
    required String afterLabel,
    required Color changeColor,
    required AppLocalizations l10n,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(l10n.auditBeforeLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Text(beforeLabel,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: changeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: changeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(changeLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: changeColor)),
                ),
                const SizedBox(height: 3),
                Icon(Icons.arrow_forward,
                    color: Colors.grey.shade400, size: 18),
              ],
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(l10n.auditAfterLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Text(afterLabel,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue.shade700)),
                ],
              ),
            ),
          ],
        ),
      );

  // ── Simple before/after (plain text) ────────────────────────────────────────
  Widget _beforeAfterWidget(String before, String after, AppLocalizations l10n) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(l10n.auditBeforeLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Text(before,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Column(
              children: [
                Icon(Icons.arrow_forward,
                    color: Colors.grey.shade400, size: 22),
                const SizedBox(height: 2),
                Text(l10n.auditChangeLabel,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400)),
              ],
            ),
            Expanded(
              child: Column(
                children: [
                  Text(l10n.auditAfterLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Text(after,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue.shade700)),
                ],
              ),
            ),
          ],
        ),
      );

  // ── Route banner (src → tgt) ─────────────────────────────────────────────────
  Widget _routeBanner(
    String src,
    String tgt,
    num total,
    Color fg,
    Color bg, {
    required bool isTransfer,
    required AppLocalizations l10n,
  }) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Text(src,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: fg)),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                  isTransfer
                      ? Icons.arrow_forward
                      : Icons.copy_outlined,
                  color: fg,
                  size: 18),
            ),
            Text(tgt,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: fg)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(l10n.auditSkuTotal(total.toInt()),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: fg)),
            ),
          ],
        ),
      );

  // ── SKU detail group: handles both Map (rich) and String (legacy) items ─────
  Widget _skuDetailGroup(
      String title, List<dynamic> items, Color color, String desc, AppLocalizations l10n) {
    if (items.isEmpty) return const SizedBox.shrink();
    final isRich = items.first is Map;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 6),
            Text(l10n.auditGroupTitle(title, items.length),
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: color)),
            const SizedBox(width: 6),
            Expanded(
              child: Text('— $desc',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isRich)
          ...items.map((item) =>
              _skuDetailCard(item as Map<String, dynamic>, color, l10n))
        else
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: items
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: color.withValues(alpha: 0.25)),
                      ),
                      child: Text(s.toString(),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: color)),
                    ))
                .toList(),
          ),
      ],
    );
  }

  // ── Individual SKU detail card for batch ops ────────────────────────────────
  Widget _skuDetailCard(Map<String, dynamic> item, Color color, AppLocalizations l10n) {
    final skuCode = item['skuCode']?.toString() ?? '';
    final qty = (item['qty'] as num?) ?? 0;
    final configs = _toMapList(item['configs']);
    final beforeTargetQty = item['beforeTargetQty'] as num?;
    final afterTargetQty = item['afterTargetQty'] as num?;
    final beforeTargetConfigs = _toMapList(item['beforeTargetConfigs']);
    final afterTargetConfigs = _toMapList(item['afterTargetConfigs']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 13, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(skuCode,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color)),
              ),
              _pill(l10n.auditQtyPcs(qty.toInt()), color, bold: true),
            ],
          ),
          if (configs.isNotEmpty) ...[
            const SizedBox(height: 8),
            _configsBlock(configs, highlightColor: color, l10n: l10n),
          ],
          if (beforeTargetQty != null && afterTargetQty != null) ...[
            const Divider(height: 16),
            Text(l10n.auditTargetLocationChange,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 6),
            if (beforeTargetConfigs.isNotEmpty &&
                afterTargetConfigs.isNotEmpty)
              _configsBeforeAfterWidget(
                  beforeTargetConfigs, afterTargetConfigs, l10n)
            else
              _beforeAfterWidget(
                  l10n.auditQtyPcs(beforeTargetQty.toInt()),
                  l10n.auditQtyPcs(afterTargetQty.toInt()),
                  l10n),
          ],
        ],
      ),
    );
  }

  // ── Qty highlight badge ─────────────────────────────────────────────────────
  Widget _qtyHighlight(String text, Color color) => Container(
        margin: const EdgeInsets.only(top: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 16, color: color),
            const SizedBox(width: 8),
            Text(text,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: color)),
          ],
        ),
      );

  // ── Helpers ─────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _toMapList(dynamic v) => v == null
      ? []
      : (v as List).whereType<Map<String, dynamic>>().toList();

  List<String> _toList(dynamic v) =>
      v == null ? [] : List<String>.from(v as List);
}
