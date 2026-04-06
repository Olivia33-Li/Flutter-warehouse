import 'package:flutter/material.dart';

/// Strip common separators and lowercase — warehouse fuzzy matching core.
String normalizeQuery(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[-_/\s"]+'), '');

/// Returns true if [text] contains [query] after normalization.
bool fuzzyMatch(String text, String query) {
  if (query.isEmpty) return true;
  return normalizeQuery(text).contains(normalizeQuery(query));
}

/// Returns true if any of [fields] fuzzy-matches [query].
bool fuzzyMatchAny(List<String> fields, String query) {
  if (query.isEmpty) return true;
  final q = normalizeQuery(query);
  return fields.any((f) => normalizeQuery(f).contains(q));
}

/// Build a [TextSpan] that highlights the first occurrence of [query] in [text].
/// Works on the original string by finding the best aligned substring.
TextSpan highlightMatch(
  String text,
  String query, {
  TextStyle? baseStyle,
  TextStyle? highlightStyle,
}) {
  final hl = highlightStyle ??
      const TextStyle(
        fontWeight: FontWeight.bold,
        backgroundColor: Color(0xFFFFE082),
      );

  if (query.isEmpty || text.isEmpty) {
    return TextSpan(text: text, style: baseStyle);
  }

  final normText = normalizeQuery(text);
  final normQuery = normalizeQuery(query);
  final matchIdx = normText.indexOf(normQuery);
  if (matchIdx == -1) {
    return TextSpan(text: text, style: baseStyle);
  }

  // Map normalized index → original index using a character-by-character walk.
  // We build a list where normToOrig[i] = original char index when norm index == i.
  final normToOrig = <int>[]; // normToOrig[normPos] = origPos
  for (int i = 0; i < text.length; i++) {
    final ch = text[i];
    final normCh = normalizeQuery(ch);
    // normCh may be empty (if ch is a separator stripped by normalizeQuery)
    for (int k = 0; k < normCh.length; k++) {
      normToOrig.add(i);
    }
  }
  normToOrig.add(text.length); // sentinel

  if (matchIdx >= normToOrig.length || matchIdx + normQuery.length > normToOrig.length) {
    return TextSpan(text: text, style: baseStyle);
  }

  final origStart = normToOrig[matchIdx];
  final origEnd = normToOrig[matchIdx + normQuery.length];

  if (origStart == origEnd) {
    return TextSpan(text: text, style: baseStyle);
  }

  return TextSpan(
    style: baseStyle,
    children: [
      if (origStart > 0) TextSpan(text: text.substring(0, origStart)),
      TextSpan(text: text.substring(origStart, origEnd), style: hl),
      if (origEnd < text.length) TextSpan(text: text.substring(origEnd)),
    ],
  );
}
