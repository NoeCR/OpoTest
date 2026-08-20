import 'package:flutter_test/flutter_test.dart';
import 'package:testea_local/database/app_database.dart';
import 'package:testea_local/features/random_tests/application/random_test_service.dart';
import 'package:testea_local/features/random_tests/domain/random_test_mode.dart';
import 'package:testea_local/models/local_user.dart';

import 'helpers/database_helper.dart';

void main() {
  group('RandomTestService', () {
    late AppDatabase db;
    late RandomTestService service;
    late LocalUser user;

    setUp(() async {
      db = await setUpTestDatabase();
      service = RandomTestService(db);
      user = LocalUser(
        id: 'user-random',
        name: 'Ana',
        createdAt: DateTime.parse('2026-01-01T00:00:00'),
      );
      await db.upsertUser(user);
    });

    tearDown(tearDownTestDatabase);

    test('classic elige un test cuando hay temario', () async {
      await db.upsertOfficialTest(sampleTestJson(id: '5001'));
      await db.upsertOfficialTest(sampleTestJson(id: '5002', lawId: '11'));

      final pick = await service.pick(mode: RandomTestMode.classic, userId: user.id);
      expect(pick.isEmpty, isFalse);
      expect(['5001', '5002'], contains(pick.testId));
    });

    test('practiced solo elige tests ya intentados', () async {
      await db.upsertOfficialTest(sampleTestJson(id: '5010'));
      await db.upsertOfficialTest(sampleTestJson(id: '5011', lawId: '11'));
      await db.saveAttempt(TestAttempt(
        id: 'att-practiced',
        userId: user.id,
        testId: '5010',
        testName: 'Hecho',
        finishedAt: DateTime.parse('2026-08-01T10:00:00'),
        durationSeconds: 120,
        netScore: 8,
        percentScore: 80,
        answers: const {0: 1},
        examSimulation: false,
        errorFormat: 100,
      ));

      for (var i = 0; i < 8; i++) {
        final pick = await service.pick(mode: RandomTestMode.practiced, userId: user.id);
        expect(pick.testId, '5010');
      }
    });

    test('mostErrors prioriza tests con fallos recientes', () async {
      await db.upsertOfficialTest(sampleTestJson(id: '5020', questionCount: 4));
      await db.upsertOfficialTest(sampleTestJson(id: '5021', lawId: '11', questionCount: 4));
      await db.saveAttempt(TestAttempt(
        id: 'att-good',
        userId: user.id,
        testId: '5020',
        testName: 'Bueno',
        finishedAt: DateTime.parse('2026-08-19T10:00:00'),
        durationSeconds: 60,
        netScore: 4,
        percentScore: 100,
        answers: const {0: 1, 1: 2, 2: 3, 3: 4},
        examSimulation: false,
        errorFormat: 100,
      ));
      await db.saveAttempt(TestAttempt(
        id: 'att-bad',
        userId: user.id,
        testId: '5021',
        testName: 'Malo',
        finishedAt: DateTime.parse('2026-08-20T10:00:00'),
        durationSeconds: 60,
        netScore: 1,
        percentScore: 25,
        answers: const {0: 2, 1: 1, 2: 1, 3: 1},
        examSimulation: false,
        errorFormat: 100,
      ));

      final pick = await service.pick(mode: RandomTestMode.mostErrors, userId: user.id);
      expect(pick.testId, '5021');
    });

    test('mixed genera test sintético con preguntas', () async {
      await db.upsertOfficialTest(sampleTestJson(id: '5030', lawId: '20'));
      await db.upsertOfficialTest(sampleTestJson(id: '5031', lawId: '21'));

      final pick = await service.pick(mode: RandomTestMode.mixed, userId: user.id);
      expect(pick.isEmpty, isFalse);
      expect(pick.mixedTest, isNotNull);
      expect(pick.mixedTest!.questions, isNotEmpty);
      expect(pick.mixedTest!.type, 'mixed');
    });
  });
}
