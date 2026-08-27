import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/models/law_sort_mode.dart';
import 'package:opotest/utils/law_sort.dart';
import 'package:opotest/utils/qmap.dart';

Map<String, dynamic> _law(String id, String code, {int order = 0}) => {
      'id': id,
      'code': code,
      'name': code,
      'order_idx': order,
    };

void main() {
  group('lawCodeCategory', () {
    test('clasifica leyes, decretos y otros', () {
      expect(lawCodeCategory('L39/2015'), LawCodeCategory.ley);
      expect(lawCodeCategory('LO3/1981'), LawCodeCategory.ley);
      expect(lawCodeCategory('RDL5/2015'), LawCodeCategory.ley);
      expect(lawCodeCategory('RD364/1995'), LawCodeCategory.decreto);
      expect(lawCodeCategory('RUE679/2016'), LawCodeCategory.decreto);
      expect(lawCodeCategory('CONSTITUCIÓN'), LawCodeCategory.constitucion);
      expect(lawCodeCategory('Agenda 2030'), LawCodeCategory.other);
    });
  });

  group('sortLaws', () {
    final laws = [
      _law('5', 'CONSTITUCIÓN', order: 1),
      _law('6', 'L39/2015', order: 2),
      _law('7', 'RD364/1995', order: 3),
      _law('8', 'L40/2015', order: 4),
    ];

    final progress = {
      '5': const ProgressCounts(done: 10, total: 20),
      '6': const ProgressCounts(done: 5, total: 10),
      '7': const ProgressCounts(done: 8, total: 10),
      '8': const ProgressCounts(done: 1, total: 10),
    };

    test('temario respeta order_idx', () {
      final sorted = sortLaws(laws, LawSortMode.temario, progress);
      expect(sorted.map((l) => l['code']).toList(), [
        'CONSTITUCIÓN',
        'L39/2015',
        'RD364/1995',
        'L40/2015',
      ]);
    });

    test('leyes primero agrupa L/LO/RDL antes que RD', () {
      final sorted = sortLaws(laws, LawSortMode.leyesFirst, progress);
      final codes = sorted.map((l) => l['code'] as String).toList();
      expect(codes.indexOf('L39/2015'), lessThan(codes.indexOf('RD364/1995')));
      expect(codes.indexOf('L40/2015'), lessThan(codes.indexOf('RD364/1995')));
      expect(codes.indexOf('CONSTITUCIÓN'), lessThan(codes.indexOf('RD364/1995')));
    });

    test('decretos primero coloca RD al inicio', () {
      final sorted = sortLaws(laws, LawSortMode.decretosFirst, progress);
      expect(sorted.first['code'], 'RD364/1995');
    });

    test('progreso descendente prioriza mayor ratio', () {
      final sorted = sortLaws(laws, LawSortMode.progressDesc, progress);
      expect(sorted.first['code'], 'RD364/1995');
      expect(sorted.last['code'], 'L40/2015');
    });

    test('nombre ordena alfabéticamente', () {
      final sorted = sortLaws(laws, LawSortMode.nombre, progress);
      expect(sorted.first['code'], 'CONSTITUCIÓN');
      expect(sorted.last['code'], 'RD364/1995');
    });

    test('personalizado respeta el orden guardado', () {
      final sorted = sortLaws(
        laws,
        LawSortMode.custom,
        progress,
        customOrder: ['8', '5', '7', '6'],
      );
      expect(sorted.map((l) => l['id']).toList(), ['8', '5', '7', '6']);
    });

    test('personalizado coloca ids nuevos al final', () {
      final sorted = sortLaws(
        laws,
        LawSortMode.custom,
        progress,
        customOrder: ['7', '6'],
      );
      expect(sorted.map((l) => l['id']).toList(), ['7', '6', '5', '8']);
    });
  });

  group('mergeCustomLawOrder', () {
    test('conserva orden, omite desaparecidos y añade nuevos al final', () {
      expect(
        mergeCustomLawOrder(['6', 'gone', '8', '6'], ['8', '5', '6']),
        ['6', '8', '5'],
      );
    });

    test('sin orden previo usa el orden actual', () {
      expect(mergeCustomLawOrder(const [], ['5', '6']), ['5', '6']);
    });
  });

  test('lawSortModeFromStorage usa temario por defecto', () {
    expect(lawSortModeFromStorage(null), LawSortMode.temario);
    expect(lawSortModeFromStorage('leyesFirst'), LawSortMode.leyesFirst);
    expect(lawSortModeFromStorage('custom'), LawSortMode.custom);
  });
}
