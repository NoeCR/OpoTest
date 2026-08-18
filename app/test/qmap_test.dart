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
  });

  test('ContentKind incluye preguntas propias', () {
    expect(ContentKind.own.label, 'Preguntas propias');
    expect(ContentKind.own.dbType, 'own');
  });
}
