import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/database/app_database.dart';
import 'package:opotest/features/daily_focus/application/daily_focus_service.dart';
import 'package:opotest/features/daily_focus/domain/daily_focus.dart';
import 'package:opotest/features/failed_questions_export/application/failed_questions_collector.dart';
import 'package:opotest/models/local_user.dart';

import '../../helpers/database_helper.dart';

void main() {
  group('DailyFocusService', () {
    late AppDatabase db;
    late DailyFocusService service;
    late LocalUser user;
    final now = DateTime(2026, 8, 27, 12);

    setUp(() async {
      db = await setUpTestDatabase();
      service = DailyFocusService(db, FailedQuestionsCollector(db));
      user = LocalUser(
        id: 'user-1',
        name: 'Ana',
        createdAt: DateTime.parse('2026-01-01T00:00:00'),
      );
      await db.upsertUser(user);
      await db.upsertOfficialTest(sampleTestJson(id: '1001', name: 'Test débil'));
      await db.upsertOfficialTest(sampleTestJson(id: '1002', name: 'Otro test', lawId: '11'));
    });

    tearDown(tearDownTestDatabase);

    Future<void> saveAttempt({
      required String id,
      required String testId,
      required DateTime finishedAt,
      required Map<int, int> answers,
      required double percent,
    }) {
      return db.saveAttempt(TestAttempt(
        id: id,
        userId: user.id,
        testId: testId,
        testName: testId,
        finishedAt: finishedAt,
        durationSeconds: 60,
        netScore: 5,
        percentScore: percent,
        answers: answers,
        examSimulation: false,
        errorFormat: 100,
      ));
    }

    test('marcas recientes ganan a fallos', () async {
      await saveAttempt(
        id: 'att-fail',
        testId: '1001',
        finishedAt: now.subtract(const Duration(days: 1)),
        answers: const {0: 2},
        percent: 40,
      );
      await db.toggleMarkedQuestion(userId: user.id, testId: '1002', questionIndex: 0);

      final plan = await service.planFor(userId: user.id, contentReady: true, now: now);
      expect(plan.primary.kind, DailyFocusKind.markedReview);
      expect(plan.secondary.first.kind, DailyFocusKind.reinforcement);
    });

    test('marcas antiguas no cuentan y gana el test flojo o los fallos', () async {
      await db.toggleMarkedQuestion(userId: user.id, testId: '1002', questionIndex: 0);
      await AppDatabase.db.update(
        'marked_questions',
        {'marked_at': now.subtract(const Duration(days: 40)).toIso8601String()},
        where: 'user_id = ? AND test_id = ?',
        whereArgs: [user.id, '1002'],
      );
      await saveAttempt(
        id: 'att-old-fail',
        testId: '1001',
        finishedAt: now.subtract(const Duration(days: 20)),
        answers: const {0: 1},
        percent: 30,
      );

      final plan = await service.planFor(userId: user.id, contentReady: true, now: now);
      expect(plan.primary.kind, DailyFocusKind.weakTest);
      expect(plan.primary.testId, '1001');
    });

    test('sin historial y con temario propone azar', () async {
      final plan = await service.planFor(userId: user.id, contentReady: true, now: now);
      expect(plan.primary.kind, DailyFocusKind.classic);
    });

    test('fallos de 7 días proponen refuerzo', () async {
      await saveAttempt(
        id: 'att-fail-recent',
        testId: '1001',
        finishedAt: now.subtract(const Duration(days: 2)),
        answers: const {0: 2},
        percent: 50,
      );

      final plan = await service.planFor(userId: user.id, contentReady: true, now: now);
      expect(plan.primary.kind, DailyFocusKind.reinforcement);
      expect(plan.primary.reason, contains('7 días'));
    });

    test('fallos de hace más de 7 días no entran en refuerzo', () async {
      await saveAttempt(
        id: 'att-fail-old',
        testId: '1001',
        finishedAt: now.subtract(const Duration(days: 10)),
        answers: const {0: 2},
        percent: 40,
      );

      final plan = await service.planFor(userId: user.id, contentReady: true, now: now);
      expect(plan.primary.kind, DailyFocusKind.weakTest);
      expect(plan.primary.testId, '1001');
    });

    test('elige el test con peor último porcentaje', () async {
      await saveAttempt(
        id: 'att-ok',
        testId: '1002',
        finishedAt: now.subtract(const Duration(hours: 2)),
        answers: const {0: 1},
        percent: 80,
      );
      await saveAttempt(
        id: 'att-bad',
        testId: '1001',
        finishedAt: now.subtract(const Duration(hours: 1)),
        answers: const {0: 1},
        percent: 25,
      );

      final plan = await service.planFor(userId: user.id, contentReady: true, now: now);
      expect(plan.primary.kind, DailyFocusKind.weakTest);
      expect(plan.primary.testId, '1001');
      expect(plan.primary.title, 'Test débil');
    });

    test('un último intento sintético no se reintenta', () async {
      await saveAttempt(
        id: 'att-mix',
        testId: 'mixed_random_1',
        finishedAt: now,
        answers: const {0: 1},
        percent: 70,
      );

      final plan = await service.planFor(userId: user.id, contentReady: true, now: now);
      expect(plan.primary.kind, DailyFocusKind.classic);
    });

    test('sin temario y sin datos pide importar', () async {
      final plan = await service.planFor(userId: user.id, contentReady: false, now: now);
      expect(plan.primary.kind, DailyFocusKind.getStarted);
    });
  });
}
