import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/change_record.dart';

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
        return (Colors.indigo.shade600, Colors.indigo.shade50, Icons.swap_horiz);
      case '批量复制':
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

  static String badgeLabel(ChangeRecord r) {
    if (r.businessAction != null) return r.businessAction!;
    switch (r.action) {
      case 'create': return '新增';
      case 'update': return '编辑';
      case 'delete': return '删除';
      default: return r.action;
    }
  }

  static void show(BuildContext context, ChangeRecord record) {
    final style = badgeStyle(record);
    final label = badgeLabel(record);
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

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 24, color: fg),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: fg)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(record.userName,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600)),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time,
                              size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(_formatFull(record.createdAt),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: _buildBody(fg, bg),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBody(Color fg, Color bg) {
    final d = record.details;
    final ba = record.businessAction;
    final widgets = <Widget>[];

    widgets.add(_sectionCard(
      title: '基础信息',
      icon: Icons.info_outline,
      children: [
        _row('操作类型', label),
        _row('操作对象', record.entity),
        if (record.entityId != null) _row('对象 ID', record.entityId!),
        _row('操作人', record.userName),
        _row('操作时间', _formatFull(record.createdAt)),
      ],
    ));
    widgets.add(const SizedBox(height: 12));

    widgets.add(_sectionCard(
      title: '操作说明',
      icon: Icons.description_outlined,
      children: [
        Text(record.description,
            style: const TextStyle(fontSize: 13, height: 1.5)),
      ],
    ));
    widgets.add(const SizedBox(height: 12));

    if (d != null && ba != null) {
      final typeWidgets = _buildTypeDetail(d, ba, fg, bg);
      if (typeWidgets.isNotEmpty) {
        widgets.addAll(typeWidgets);
        widgets.add(const SizedBox(height: 12));
      }
    }

    if (record.changes != null && record.changes!.isNotEmpty) {
      widgets.add(_sectionCard(
        title: '字段变更',
        icon: Icons.compare_arrows,
        children: record.changes!.entries.map((e) {
          final before = e.value['before']?.toString() ?? '无';
          final after = e.value['after']?.toString() ?? '无';
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
      Map<String, dynamic> d, String ba, Color fg, Color bg) {
    switch (ba) {
      case '入库':
        return _buildStockInDetail(d, fg, bg);
      case '出库':
        return _buildStockOutDetail(d, fg, bg);
      case '调整':
        return _buildAdjustDetail(d, fg, bg);
      case '录入':
        return _buildCreateDetail(d, fg, bg);
      case '删除库存':
        return _buildDeleteInventoryDetail(d);
      case '结构修改':
        return _buildStructureDetail(d, fg, bg);
      case '批量转移':
        return _buildBatchTransferDetail(d, fg, bg);
      case '批量复制':
        return _buildBatchCopyDetail(d, fg, bg);
      case '标记已检查':
      case '取消已检查':
        return _buildCheckDetail(d, ba, fg, bg);
      case '新建库位':
      case '编辑库位':
      case '删除库位':
        return _buildLocationDetail(d, ba);
      default:
        return [];
    }
  }

  // ── 入库 ─────────────────────────────────────────────────────────────────────
  List<Widget> _buildStockInDetail(
      Map<String, dynamic> d, Color fg, Color bg) {
    final boxes = (d['boxes'] ?? 0) as num;
    final upb = (d['unitsPerBox'] ?? 1) as num;
    final addedQty = (d['addedQty'] ?? boxes * upb) as num;
    final beforeQty = (d['beforeQty'] as num?) ?? 0;
    final afterQty = (d['afterQty'] as num?) ?? beforeQty + addedQty;

    return [
      _sectionCard(
        title: '入库内容',
        icon: Icons.add_box_outlined,
        children: [
          _row('SKU', d['skuCode']),
          _row('库位', d['locationCode']),
          const SizedBox(height: 8),
          _configsBlock(
            [{'boxes': boxes, 'unitsPerBox': upb}],
            highlightColor: Colors.green.shade600,
          ),
        ],
      ),
      const SizedBox(height: 12),
      _sectionCard(
        title: '前后变化',
        icon: Icons.show_chart,
        children: [
          _inventoryChangeWidget(
            beforeLabel: '$beforeQty件',
            changeLabel: '+$addedQty件',
            afterLabel: '$afterQty件',
            changeColor: Colors.green.shade600,
          ),
        ],
      ),
    ];
  }

  // ── 出库 ─────────────────────────────────────────────────────────────────────
  List<Widget> _buildStockOutDetail(
      Map<String, dynamic> d, Color fg, Color bg) {
    final reduced = (d['reducedQty'] ?? 0) as num;
    final remaining = (d['remainingQty'] as num?) ?? 0;
    final beforeQty = reduced + remaining;

    return [
      _sectionCard(
        title: '出库内容',
        icon: Icons.outbox_outlined,
        children: [
          _row('SKU', d['skuCode']),
          _row('库位', d['locationCode']),
          const SizedBox(height: 8),
          _qtyHighlight('-$reduced件', Colors.orange.shade700),
        ],
      ),
      const SizedBox(height: 12),
      _sectionCard(
        title: '前后变化',
        icon: Icons.show_chart,
        children: [
          _inventoryChangeWidget(
            beforeLabel: '$beforeQty件',
            changeLabel: '-$reduced件',
            afterLabel: '$remaining件',
            changeColor: Colors.orange.shade700,
          ),
        ],
      ),
    ];
  }

  // ── 调整 ─────────────────────────────────────────────────────────────────────
  List<Widget> _buildAdjustDetail(
      Map<String, dynamic> d, Color fg, Color bg) {
    final beforeQty = d['beforeQty'] as num?;
    final afterQty = d['afterQty'] as num?;
    final mode = d['mode'] == 'config' ? '按箱规调整' : '按总数量调整';
    final note = d['note']?.toString();

    return [
      _sectionCard(
        title: '调整内容',
        icon: Icons.tune,
        children: [
          _row('SKU', d['skuCode']),
          _row('库位', d['locationCode']),
          _row('调整方式', mode),
          if (note != null && note.isNotEmpty) _row('备注', note),
        ],
      ),
      if (beforeQty != null && afterQty != null) ...[
        const SizedBox(height: 12),
        _sectionCard(
          title: '前后变化',
          icon: Icons.show_chart,
          children: [
            _beforeAfterWidget('$beforeQty件', '$afterQty件'),
          ],
        ),
      ],
    ];
  }

  // ── 录入 ─────────────────────────────────────────────────────────────────────
  List<Widget> _buildCreateDetail(
      Map<String, dynamic> d, Color fg, Color bg) {
    final boxes = (d['boxes'] ?? 0) as num;
    final upb = (d['unitsPerBox'] ?? 1) as num;
    final quantity = (d['quantity'] ?? boxes * upb) as num;

    return [
      _sectionCard(
        title: '录入内容',
        icon: Icons.edit_note,
        children: [
          _row('SKU', d['skuCode']),
          _row('库位', d['locationCode']),
          const SizedBox(height: 8),
          _configsBlock(
            [{'boxes': boxes, 'unitsPerBox': upb}],
            highlightColor: Colors.teal.shade600,
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
              '首次录入 · 共$quantity件',
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
  List<Widget> _buildDeleteInventoryDetail(Map<String, dynamic> d) {
    final quantity = (d['quantity'] ?? 0) as num;
    final configs = _toMapList(d['configurations']);

    return [
      _sectionCard(
        title: '删除内容',
        icon: Icons.delete_outline,
        children: [
          _row('SKU', d['skuCode']),
          _row('库位', d['locationCode']),
          const SizedBox(height: 8),
          if (configs.isNotEmpty)
            _configsBlock(configs, highlightColor: Colors.red.shade600)
          else
            _qtyHighlight('$quantity件', Colors.red.shade600),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_outlined,
                    size: 14, color: Colors.red),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '该 SKU 在此库位的所有库存数据已删除，此操作不可恢复。',
                    style: TextStyle(fontSize: 12, color: Colors.red),
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
      Map<String, dynamic> d, Color fg, Color bg) {
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
        title: '修改内容',
        icon: Icons.construction_outlined,
        children: [
          _row('SKU', d['skuCode']),
          _row('库位', d['locationCode']),
        ],
      ),
      if (effectiveBefore.isNotEmpty || effectiveAfter.isNotEmpty) ...[
        const SizedBox(height: 12),
        _sectionCard(
          title: '前后变化',
          icon: Icons.show_chart,
          children: [
            _configsBeforeAfterWidget(effectiveBefore, effectiveAfter),
          ],
        ),
      ] else if (beforeQty != null && afterQty != null) ...[
        const SizedBox(height: 12),
        _sectionCard(
          title: '前后变化',
          icon: Icons.show_chart,
          children: [_beforeAfterWidget('$beforeQty件', '$afterQty件')],
        ),
      ],
    ];
  }

  // ── 批量转移 ─────────────────────────────────────────────────────────────────
  List<Widget> _buildBatchTransferDetail(
      Map<String, dynamic> d, Color fg, Color bg) {
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
        title: '转移路径',
        icon: Icons.swap_horiz,
        children: [
          _routeBanner(d['sourceCode'] ?? '', d['targetCode'] ?? '',
              total, fg, bg,
              isTransfer: true),
          const SizedBox(height: 8),
          _row('来源库位', d['sourceCode']),
          _row('目标库位', d['targetCode']),
          _row('SKU 总数', '$total种'),
        ],
      ),
      const SizedBox(height: 12),
      _sectionCard(
        title: '涉及明细',
        icon: Icons.list_alt_outlined,
        children: [
          if (moved.isNotEmpty) ...[
            _skuDetailGroup('直接转移', moved, Colors.green.shade700,
                '目标库位原无此 SKU，直接写入'),
            if (merged.isNotEmpty || overwritten.isNotEmpty)
              const SizedBox(height: 12),
          ],
          if (merged.isNotEmpty) ...[
            _skuDetailGroup('合并', merged, Colors.blue.shade700,
                '与目标库位已有库存合并，按箱规叠加'),
            if (overwritten.isNotEmpty) const SizedBox(height: 12),
          ],
          if (overwritten.isNotEmpty)
            _skuDetailGroup('覆盖', overwritten, Colors.red.shade700,
                '用来源库存替换了目标库位的原有库存'),
        ],
      ),
      const SizedBox(height: 12),
      _sectionCard(
        title: '影响结果',
        icon: Icons.info_outline,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_outlined,
                    size: 15, color: Colors.amber),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '转移完成后，来源库位中对应的 SKU 库存数据已被删除。\n目标库位已新增或更新上述 SKU 的库存。',
                    style: TextStyle(fontSize: 12, height: 1.5),
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
      Map<String, dynamic> d, Color fg, Color bg) {
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
        title: '复制路径',
        icon: Icons.copy_outlined,
        children: [
          _routeBanner(d['sourceCode'] ?? '', d['targetCode'] ?? '',
              total, fg, bg,
              isTransfer: false),
          const SizedBox(height: 8),
          _row('来源库位', d['sourceCode']),
          _row('目标库位', d['targetCode']),
          _row('SKU 总数', '$total种'),
          _row('来源库位', '无变化（复制操作不删除来源数据）'),
        ],
      ),
      const SizedBox(height: 12),
      _sectionCard(
        title: '涉及明细',
        icon: Icons.list_alt_outlined,
        children: [
          if (copied.isNotEmpty) ...[
            _skuDetailGroup('直接复制', copied, Colors.green.shade700,
                '目标库位原无此 SKU，直接写入'),
            if (stacked.isNotEmpty || overwritten.isNotEmpty)
              const SizedBox(height: 12),
          ],
          if (stacked.isNotEmpty) ...[
            _skuDetailGroup('叠加', stacked, Colors.blue.shade700,
                '与目标库位已有库存叠加，按箱规合并'),
            if (overwritten.isNotEmpty) const SizedBox(height: 12),
          ],
          if (overwritten.isNotEmpty)
            _skuDetailGroup('覆盖', overwritten, Colors.red.shade700,
                '用来源库存替换了目标库位的原有库存'),
        ],
      ),
    ];
  }

  // ── 检查状态 ─────────────────────────────────────────────────────────────────
  List<Widget> _buildCheckDetail(
      Map<String, dynamic> d, String ba, Color fg, Color bg) {
    return [
      _sectionCard(
        title: '检查状态',
        icon: Icons.check_circle_outline,
        children: [
          _row('库位', d['locationCode']),
          _row('状态变化',
              ba == '标记已检查' ? '未检查  →  已检查' : '已检查  →  未检查'),
          if (d['checkedBy'] != null) _row('检查人', d['checkedBy']),
          if (d['checkedAt'] != null)
            _row(
                '检查时间',
                DateFormat('yyyy-MM-dd HH:mm').format(
                    DateTime.parse(d['checkedAt']).toLocal())),
        ],
      ),
    ];
  }

  // ── 库位操作 ─────────────────────────────────────────────────────────────────
  List<Widget> _buildLocationDetail(Map<String, dynamic> d, String ba) {
    final iconData = ba == '新建库位'
        ? Icons.add_location_alt_outlined
        : ba == '编辑库位'
            ? Icons.edit_location_alt_outlined
            : Icons.wrong_location_outlined;
    return [
      _sectionCard(
        title: '库位信息',
        icon: iconData,
        children: [
          _row('库位编码', d['locationCode']),
          if (d['description'] != null &&
              d['description'].toString().isNotEmpty)
            _row('描述', d['description']),
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
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Icon(icon, size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey.shade700)),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
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
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13)),
            ),
            Expanded(
              child: Text(value?.toString() ?? '-',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

  // ── Carton structure block: [N箱] × [M件/箱] = [X件] ───────────────────────
  Widget _configsBlock(List<dynamic> configs, {Color? highlightColor}) {
    if (configs.isEmpty) {
      return Text('无库存',
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
              _pill('$boxes 箱', Colors.grey.shade600),
              Text('×',
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                      fontWeight: FontWeight.w300)),
              _pill('$upb 件/箱', Colors.grey.shade600),
              Text('=',
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                      fontWeight: FontWeight.w300)),
              _pill('$total 件', color, bold: true),
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
      List<dynamic> before, List<dynamic> after) =>
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
                  Text('操作前',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  _configsBlock(before),
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
                  Text('变化',
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
                  Text('操作后',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  _configsBlock(after,
                      highlightColor: Colors.blue.shade700),
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
                  Text('操作前',
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
                  Text('操作后',
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
  Widget _beforeAfterWidget(String before, String after) =>
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
                  Text('操作前',
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
                Text('变化',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400)),
              ],
            ),
            Expanded(
              child: Column(
                children: [
                  Text('操作后',
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
              child: Text('共$total种',
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
      String title, List<dynamic> items, Color color, String desc) {
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
            Text('$title（${items.length}种）',
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
              _skuDetailCard(item as Map<String, dynamic>, color))
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
  Widget _skuDetailCard(Map<String, dynamic> item, Color color) {
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
              _pill('$qty 件', color, bold: true),
            ],
          ),
          if (configs.isNotEmpty) ...[
            const SizedBox(height: 8),
            _configsBlock(configs, highlightColor: color),
          ],
          if (beforeTargetQty != null && afterTargetQty != null) ...[
            const Divider(height: 16),
            Text('目标库位变化',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 6),
            if (beforeTargetConfigs.isNotEmpty &&
                afterTargetConfigs.isNotEmpty)
              _configsBeforeAfterWidget(
                  beforeTargetConfigs, afterTargetConfigs)
            else
              _beforeAfterWidget(
                  '$beforeTargetQty件', '$afterTargetQty件'),
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
