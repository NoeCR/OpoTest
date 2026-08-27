import '../models/law_sort_mode.dart';
import 'qmap.dart';

enum LawCodeCategory { ley, decreto, constitucion, other }

LawCodeCategory lawCodeCategory(String code) {
  final normalized = cleanText(code).toUpperCase();
  if (normalized.contains('CONSTITU')) return LawCodeCategory.constitucion;
  if (_startsWithLawPrefix(normalized)) return LawCodeCategory.ley;
  if (_startsWithDecretoPrefix(normalized)) return LawCodeCategory.decreto;
  return LawCodeCategory.other;
}

bool _startsWithLawPrefix(String code) {
  return RegExp(r'^L\d').hasMatch(code) ||
      RegExp(r'^LO\d').hasMatch(code) ||
      RegExp(r'^RDL\d').hasMatch(code);
}

bool _startsWithDecretoPrefix(String code) {
  return RegExp(r'^RD\d').hasMatch(code) || RegExp(r'^RUE\d').hasMatch(code);
}

int _categoryRank(LawCodeCategory category, LawSortMode mode) {
  return switch (mode) {
    LawSortMode.leyesFirst => switch (category) {
        LawCodeCategory.ley => 0,
        LawCodeCategory.constitucion => 1,
        LawCodeCategory.decreto => 2,
        LawCodeCategory.other => 3,
      },
    LawSortMode.decretosFirst => switch (category) {
        LawCodeCategory.decreto => 0,
        LawCodeCategory.ley => 1,
        LawCodeCategory.constitucion => 2,
        LawCodeCategory.other => 3,
      },
    _ => 0,
  };
}

int _orderIndex(Map<String, dynamic> law) =>
    (law['order_idx'] as num?)?.toInt() ?? 0;

String _lawCode(Map<String, dynamic> law) =>
    cleanText(law['code']?.toString() ?? law['name']?.toString());

double _progressRatio(Map<String, dynamic> law, Map<String, ProgressCounts> progressByLaw) {
  final id = law['id']?.toString() ?? '';
  return progressByLaw[id]?.ratio ?? 0;
}

/// Conserva el orden guardado, omite ids desaparecidos y añade los nuevos al final.
List<String> mergeCustomLawOrder(List<String> savedOrder, Iterable<String> currentIds) {
  final current = currentIds.toList();
  final currentSet = current.toSet();
  final merged = <String>[];
  final seen = <String>{};
  for (final id in savedOrder) {
    if (currentSet.contains(id) && seen.add(id)) {
      merged.add(id);
    }
  }
  for (final id in current) {
    if (seen.add(id)) merged.add(id);
  }
  return merged;
}

int _customOrderRank(Map<String, dynamic> law, List<String> customOrder) {
  final index = customOrder.indexOf(law['id']?.toString() ?? '');
  return index < 0 ? customOrder.length : index;
}

List<Map<String, dynamic>> sortLaws(
  List<Map<String, dynamic>> laws,
  LawSortMode mode,
  Map<String, ProgressCounts> progressByLaw, {
  List<String> customOrder = const [],
}) {
  final sorted = List<Map<String, dynamic>>.from(laws);
  sorted.sort((a, b) {
    final primary = switch (mode) {
      LawSortMode.temario => _orderIndex(a).compareTo(_orderIndex(b)),
      LawSortMode.progressDesc =>
        _progressRatio(b, progressByLaw).compareTo(_progressRatio(a, progressByLaw)),
      LawSortMode.progressAsc =>
        _progressRatio(a, progressByLaw).compareTo(_progressRatio(b, progressByLaw)),
      LawSortMode.leyesFirst || LawSortMode.decretosFirst => () {
          final catCmp = _categoryRank(lawCodeCategory(_lawCode(a)), mode)
              .compareTo(_categoryRank(lawCodeCategory(_lawCode(b)), mode));
          if (catCmp != 0) return catCmp;
          return _lawCode(a).toUpperCase().compareTo(_lawCode(b).toUpperCase());
        }(),
      LawSortMode.nombre =>
        _lawCode(a).toUpperCase().compareTo(_lawCode(b).toUpperCase()),
      LawSortMode.custom =>
        _customOrderRank(a, customOrder).compareTo(_customOrderRank(b, customOrder)),
    };
    if (primary != 0) return primary;
    return _orderIndex(a).compareTo(_orderIndex(b));
  });
  return sorted;
}
