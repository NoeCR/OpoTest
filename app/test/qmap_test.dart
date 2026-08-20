import 'package:flutter_test/flutter_test.dart';
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

    test('allTestIdsForTitlePayload combina qByTitle y capítulos', () {
      final payload = {
        'qByTitle': {
          '82': {'mainLevel': ['821'], 'subLevel': []},
        },
        'qByChapter': {
          '111': {'mainLevel': ['900'], 'subLevel': []},
        },
        'arChapters': [
          {'id': '111'},
        ],
        'arArticles': [],
        'qByArticle': {},
      };

      expect(
        allTestIdsForTitlePayload(payload, '82').toSet(),
        {'821', '900'},
      );
    });

    test('titleUsesHierarchy detecta capítulos con tests', () {
      final payload = {
        'qByTitle': {'82': {'mainLevel': ['821'], 'subLevel': []}},
        'qByChapter': {
          '111': {'mainLevel': ['900'], 'subLevel': []},
        },
        'arChapters': [
          {'id': '111'},
        ],
        'arArticles': [],
        'qByArticle': {},
      };

      expect(titleUsesHierarchy(payload, '82'), isTrue);
    });

    test('titleUsesHierarchy es false cuando solo hay tests del título', () {
      final payload = {
        'qByTitle': {'82': {'mainLevel': ['821', '826'], 'subLevel': []}},
        'qByChapter': [],
        'arChapters': [
          {'id': '111'},
          {'id': '112'},
        ],
        'arArticles': [],
        'qByArticle': {},
      };

      expect(titleUsesHierarchy(payload, '82'), isFalse);
      expect(titleHasTests(payload, '82'), isTrue);
      expect(titleLevelTestIds(payload, '82'), ['821', '826']);
    });

    test('titleHasTests es false sin tests', () {
      final payload = {
        'qByTitle': [],
        'qByChapter': [],
        'arChapters': [
          {'id': '125'},
        ],
        'arArticles': [],
        'qByArticle': {},
      };

      expect(titleHasTests(payload, '85'), isFalse);
    });

    test('testIdsFromQNode soporta mainLevel como mapa', () {
      final ids = testIdsFromQNode({
        'mainLevel': {
          'test': ['1', '2'],
          'exam': ['9'],
        },
      });
      expect(ids, ['1', '2', '9']);
    });

    test('chapterUsesHierarchy detecta secciones con tests', () {
      final payload = {
        'arSections': [
          {'id': '501'},
        ],
        'qBySection': {
          '501': {'mainLevel': ['777'], 'subLevel': []},
        },
        'arArticles': [],
        'qByArticle': {},
      };

      expect(chapterUsesHierarchy(payload, '100'), isTrue);
    });

    test('articleTestGroups ordena por order y filtra sin tests', () {
      final payload = {
        'arArticles': [
          {'id': 'a2', 'code': 'Art. 2', 'order': '2'},
          {'id': 'a1', 'code': 'Art. 1', 'order': '1'},
          {'id': 'a3', 'code': 'Art. 3', 'order': '3'},
        ],
        'qByArticle': {
          'a1': {'mainLevel': ['10'], 'subLevel': []},
          'a3': {'mainLevel': [], 'subLevel': []},
        },
      };

      final groups = articleTestGroups(payload);
      expect(groups, hasLength(1));
      expect(groups.first.code, 'Art. 1');
      expect(groups.first.testIds, ['10']);
    });

    test('cleanText elimina retornos y espacios', () {
      expect(cleanText('  hola\r\n'), 'hola');
      expect(cleanText(null), isEmpty);
    });

    test('progressCounts vacío tiene ratio cero', () {
      const counts = ProgressCounts(done: 0, total: 0);
      expect(counts.isEmpty, isTrue);
      expect(counts.ratio, 0);
      expect(progressLabel(const [], {}), isEmpty);
    });
  });
}
