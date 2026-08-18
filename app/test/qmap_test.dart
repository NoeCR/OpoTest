import 'package:flutter_test/flutter_test.dart';

import 'package:testea_local/models/content_kind.dart';
import 'package:testea_local/utils/qmap.dart';

void main() {
  group('qmap utils', () {
    test('testIdsFromQMap respeta main/sub', () {
      final q = {
        '20': {
          'mainLevel': ['1', '2'],
          'subLevel': ['3'],
        },
      };

      expect(testIdsFromQMap(q, '20'), ['1', '2']);
      expect(testIdsFromQMap(q, '20', includeSubLevel: true), ['1', '2', '3']);
      expect(allTestIdsFromQMap(q, '20').toSet(), {'1', '2', '3'});
    });

    test('progressCounts calcula done/total y ratio', () {
      final counts = progressCounts(['10', '11', '12'], {'10', '12'});
      expect(counts.done, 2);
      expect(counts.total, 3);
      expect(counts.label, '2/3');
      expect(counts.ratio, closeTo(2 / 3, 0.0001));
      expect(counts.complete, isFalse);
    });

    test('cleanText elimina retornos y espacios', () {
      expect(cleanText('  hola\r '), 'hola');
    });
  });

  test('ContentKind incluye preguntas propias', () {
    expect(ContentKind.own.label, 'Preguntas propias');
    expect(ContentKind.own.dbType, 'own');
  });
}
