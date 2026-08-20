import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:testea_local/database/app_database.dart';
import 'package:testea_local/models/local_user.dart';

import 'helpers/database_helper.dart';

void main() {
  group('AppDatabase', () {
    late AppDatabase db;
    late LocalUser user;

    setUp(() async {
      db = await setUpTestDatabase();
      user = LocalUser(
        id: 'user-1',
        name: 'Usuario',
        createdAt: DateTime.parse('2026-01-01T00:00:00'),
      );
      await db.upsertUser(user);
    });

    tearDown(tearDownTestDatabase);

    test('upsertUser y getUsers persisten cuentas locales', () async {
      final users = await db.getUsers();
      expect(users, hasLength(1));
      expect(users.first.name, 'Usuario');
    });

    test('activeUserId se guarda en SharedPreferences', () async {
      await db.setActiveUserId(user.id);
      expect(await db.activeUserId(), user.id);
      await db.setActiveUserId(null);
      expect(await db.activeUserId(), isNull);
    });

    test('importLawIndex guarda leyes y qByLawNew', () async {
      await db.importLawIndex({
        'laws': [
          {'id': '10', 'code': 'L10', 'name_es': 'Ley', 'order': '1'},
        ],
        'qByLawNew': {
          '10': {
            'mainLevel': {'test': ['1001', '1002']},
          },
        },
      });

      final laws = await db.getLaws();
      expect(laws, hasLength(1));
      expect(await db.getSyncMeta('q_by_law'), isNotNull);

      final ids = await db.testIdsForLawType('10', 'test');
      expect(ids, ['1001', '1002']);
    });

    test('testIdsForLawType lee tests desde subLevel cuando no hay mainLevel.test', () async {
      await db.setSyncMeta(
        'q_by_law',
        jsonEncode({
          '5': {
            'mainLevel': {
              'exam': ['204'],
              'realexam': ['203'],
            },
            'subLevel': ['24', '25', '26'],
          },
        }),
      );

      expect(await db.testIdsForLawType('5', 'test'), ['24', '25', '26']);
      expect(await db.testIdsForLawType('5', 'exam'), ['204']);
      expect(await db.testIdsForLawType('5', 'realexam'), ['203']);
    });

    test('contentIdsGroupedByLaw incluye tests, exámenes y oficiales', () async {
      await db.upsertOfficialTest(sampleTestJson(id: '8001', lawId: '5', type: 'test'));
      await db.upsertOfficialTest(sampleTestJson(id: '8002', lawId: '5', type: 'exam'));
      await db.upsertOfficialTest(sampleTestJson(id: '8003', lawId: '5', type: 'realexam'));

      final grouped = await db.contentIdsGroupedByLaw();
      expect(grouped['5'], ['8001', '8002', '8003']);
      final testsOnly = await db.testIdsGroupedByLaw();
      expect(testsOnly['5'], ['8001']);
    });

    test('testIdsForLawType soporta qByLaw legacy con lista mainLevel', () async {
      await db.setSyncMeta(
        'q_by_law',
        jsonEncode({
          '364': {
            'mainLevel': ['9001', '9002'],
          },
        }),
      );

      final ids = await db.testIdsForLawType('364', 'test');
      expect(ids, ['9001', '9002']);
    });

    test('upsertOfficialTest no pisa tests custom', () async {
      final customJson = sampleTestJson(id: '2001', name: 'Custom');
      await AppDatabase.db.insert('tests', {
        'id': '2001',
        'title_id': '82',
        'law_id': '10',
        'chapter_id': '',
        'section_id': '',
        'article_id': '',
        'name': 'Custom original',
        'type': 'test',
        'source': AppDatabase.testSourceCustom,
        'index_num': 1,
        'payload': jsonEncode(customJson),
      });

      final officialJson = sampleTestJson(id: '2001', name: 'Oficial nuevo');
      final inserted = await db.upsertOfficialTest(officialJson);
      expect(inserted, isFalse);

      final row = await AppDatabase.db.query('tests', where: 'id = ?', whereArgs: ['2001']);
      expect(row.first['name'], 'Custom original');
      expect(row.first['source'], AppDatabase.testSourceCustom);
    });

    test('upsertOfficialTest inserta test oficial nuevo', () async {
      final inserted = await db.upsertOfficialTest(sampleTestJson(id: '3001'));
      expect(inserted, isTrue);
      expect(await db.countTests(), 1);

      final def = await db.getTest('3001');
      expect(def?.name, 'Test demo');
      expect(def?.questions, hasLength(4));
    });

    test('saveAttempt y statsForTests calculan media, mejor y último', () async {
      await db.upsertOfficialTest(sampleTestJson(id: '4001'));

      await db.saveAttempt(TestAttempt(
        id: 'att-1',
        userId: user.id,
        testId: '4001',
        testName: 'Test demo',
        finishedAt: DateTime.parse('2026-08-01T10:00:00'),
        durationSeconds: 120,
        netScore: 6,
        percentScore: 60,
        answers: const {0: 1},
        examSimulation: false,
        errorFormat: 100,
      ));
      await db.saveAttempt(TestAttempt(
        id: 'att-2',
        userId: user.id,
        testId: '4001',
        testName: 'Test demo',
        finishedAt: DateTime.parse('2026-08-02T10:00:00'),
        durationSeconds: 100,
        netScore: 10,
        percentScore: 100,
        answers: const {0: 1, 1: 1},
        examSimulation: false,
        errorFormat: 100,
      ));

      final stats = await db.statsForTest(user.id, '4001');
      expect(stats.attempts, 2);
      expect(stats.avgPercent, 80);
      expect(stats.bestPercent, 100);
      expect(stats.lastPercent, 100);
      expect(stats.lastPerfect, isTrue);

      final attempted = await db.attemptedTestIds(user.id);
      expect(attempted, {'4001'});

      final last = await db.getLastAttempt(user.id);
      expect(last?['test_id'], '4001');
      expect(last?['percent_score'], 100);
    });

    test('testIdsForTitle usa payload qByTitle y capítulos', () async {
      final payload = {
        'qByTitle': {
          '82': {'mainLevel': ['5001'], 'subLevel': []},
        },
        'qByChapter': {
          '111': {'mainLevel': ['5002'], 'subLevel': []},
        },
        'arChapters': [
          {'id': '111'},
        ],
        'arArticles': [],
        'qByArticle': {},
      };

      final ids = await db.testIdsForTitle('82', payload);
      expect(ids.toSet(), {'5001', '5002'});
    });

    test('testIdsGroupedByLaw agrupa tests por ley', () async {
      await db.upsertOfficialTest(sampleTestJson(id: '6001', lawId: '10'));
      await db.upsertOfficialTest(sampleTestJson(id: '6002', lawId: '10'));
      await db.upsertOfficialTest(sampleTestJson(id: '6003', lawId: '20'));

      final grouped = await db.testIdsGroupedByLaw();
      expect(grouped['10'], ['6001', '6002']);
      expect(grouped['20'], ['6003']);
    });

    test('toggleMarkedQuestion marca y desmarca preguntas', () async {
      await db.upsertOfficialTest(sampleTestJson(id: '9001'));
      expect(await db.isQuestionMarked(user.id, '9001', 0), isFalse);

      final marked = await db.toggleMarkedQuestion(
        userId: user.id,
        testId: '9001',
        questionIndex: 0,
      );
      expect(marked, isTrue);
      expect(await db.countMarkedQuestions(user.id), 1);
      expect(await db.markedQuestionIndices(user.id, '9001'), {0});

      final unmarked = await db.toggleMarkedQuestion(
        userId: user.id,
        testId: '9001',
        questionIndex: 0,
      );
      expect(unmarked, isFalse);
      expect(await db.countMarkedQuestions(user.id), 0);
    });

    test('exportProgressSnapshot incluye marked_questions', () async {
      await db.upsertOfficialTest(sampleTestJson(id: '9002'));
      await db.toggleMarkedQuestion(
        userId: user.id,
        testId: '9002',
        questionIndex: 1,
      );

      final snapshot = await db.exportProgressSnapshot(userId: user.id);
      final marked = snapshot['marked_questions'] as List;
      expect(marked, hasLength(1));
      expect(marked.first['test_id'], '9002');
      expect(marked.first['question_index'], 1);
    });

    test('importProgressSnapshot restaura marked_questions', () async {
      await db.upsertOfficialTest(sampleTestJson(id: '9003'));
      await db.toggleMarkedQuestion(
        userId: user.id,
        testId: '9003',
        questionIndex: 0,
      );
      final snapshot = await db.exportProgressSnapshot(userId: user.id);
      await AppDatabase.db.delete('marked_questions');

      await db.importProgressSnapshot(snapshot);
      expect(await db.isQuestionMarked(user.id, '9003', 0), isTrue);
    });

    test('deleteUserData elimina usuario e intentos', () async {
      await db.upsertOfficialTest(sampleTestJson(id: '7001'));
      await db.saveAttempt(TestAttempt(
        id: 'att-del',
        userId: user.id,
        testId: '7001',
        testName: 'Test demo',
        finishedAt: DateTime.now(),
        durationSeconds: 60,
        netScore: 5,
        percentScore: 50,
        answers: const {},
        examSimulation: false,
        errorFormat: 0,
      ));

      await db.toggleMarkedQuestion(
        userId: user.id,
        testId: '7001',
        questionIndex: 0,
      );

      await db.deleteUserData(user.id);
      expect(await db.getUsers(), isEmpty);
      expect(await db.attemptsForUser(user.id), isEmpty);
      expect(await db.countMarkedQuestions(user.id), 0);
    });
  });
}
