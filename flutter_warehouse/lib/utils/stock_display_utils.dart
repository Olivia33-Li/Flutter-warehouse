import '../l10n/app_localizations.dart';

/// Builds a compact, warehouse-friendly inventory label:
///   "{cartons} carton + {noSpec} carton (no spec) + {pcs} pcs"
///
/// Rules:
/// - [loosePcs] are converted into whole cartons using [cartonQty] (if known),
///   with the remainder kept as pcs.
/// - [noSpecCartons] (unconfiguredCartons) are never merged into [configuredCartons].
/// - Segments that are zero are omitted.
/// - Returns "0 carton" when all inputs are zero.
String buildStockLabel({
  required int configuredCartons,
  required int noSpecCartons,
  required int loosePcs,
  required int? cartonQty,
  required AppLocalizations l10n,
}) {
  // Convert loosePcs → whole cartons + remainder pcs
  int convertedCartons = 0;
  int remainingPcs = loosePcs;
  if (cartonQty != null && cartonQty > 0 && loosePcs > 0) {
    convertedCartons = loosePcs ~/ cartonQty;
    remainingPcs = loosePcs % cartonQty;
  }

  final totalCartons = configuredCartons + convertedCartons;
  final ctn          = l10n.unitBox;    // "carton" / "箱"
  final pcs          = l10n.unitPiece;  // "pcs" / "件"
  final noSpecSuffix = l10n.skuNoSpec;  // "(no spec)" / "（无箱规）"

  final parts = <String>[];
  if (totalCartons > 0)  parts.add('$totalCartons $ctn');
  if (noSpecCartons > 0) parts.add('$noSpecCartons $ctn $noSpecSuffix');
  if (remainingPcs > 0)  parts.add('$remainingPcs $pcs');

  return parts.isEmpty ? '0 $ctn' : parts.join(' + ');
}
