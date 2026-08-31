import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/database/app_database.dart';
import 'package:opotest/features/daily_streak/application/daily_streak_service.dart';
import 'package:opotest/models/local_user.dart';

import '../../helpers/database_helper.dart';

void main() {
  group('DailyStreakService', () {
    late AppDatabase db;
    late DailyStreakService service;
    late LocalUser user;
    final now = DateTime(2026, 8, 31, 12);

    setUp(() async {
      db = await setUpTestDatabase();
      service = DailyStreakService(db);
      user = LocalUser(
        id: 'user-1',
        name: 'Ana',
        createdAt: DateTime.parse('2026-01-01T00:00:00'),
      );
      await db.upsertUser(user);
    });

    tearDown(tearDownTestDatabase);

    test('suma respuestas de los intentos de hoy', () async {
      await db.saveAttempt(TestAttempt(
        id: 'a1',
        userId: user.id,
        testId: '1001',
        testName: 'Uno',
        finishedAt: now,
        durationSeconds: 60,
        netScore: 5,
        percentScore: 80,
        answers: const {0: 1, 1: 2, 2: 1},
        examSimulation: false,
        errorFormat: 100,
      ));
      await db.saveAttempt(TestAttempt(
        id: 'a2',
        userId: user.id,
        testId: '1002',
        testName: 'Dos',
        finishedAt: now.subtract(const Duration(days: 1)),
        durationSeconds: 60,
        netScore: 5,
        percentScore: 50,
        answers: const {0: 1, 1: 1, 2: 1, 3: 1, 4: 1},
        examSimulation: false,
        errorFormat: 100,
      ));

      final snap = await service.snapshotFor(userId: user.id, dailyGoal: 40, now: now);
      expect(snap.questionsToday, 3);
      expect(snap.testsToday, 1);
      expect(snap.streakDays, 2);
    });
  });
}
