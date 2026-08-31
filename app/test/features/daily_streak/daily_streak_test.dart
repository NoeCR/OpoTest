import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/features/daily_streak/domain/daily_streak.dart';

void main() {
  final now = DateTime(2026, 8, 31, 10, 0);

  DailyAttemptPoint point(DateTime at, [int answered = 10]) =>
      DailyAttemptPoint(finishedAt: at, answeredCount: answered);

  group('buildDailyStreak', () {
    test('sin intentos: racha 0 y cupo a 0', () {
      final snap = buildDailyStreak(attempts: const [], dailyGoal: 40, now: now);
      expect(snap.streakDays, 0);
      expect(snap.questionsToday, 0);
      expect(snap.testsToday, 0);
      expect(snap.goalMet, isFalse);
      expect(snap.streakLabel, 'Sin racha');
      expect(snap.cupoLabel, '0 / 40 preguntas hoy');
    });

    test('cuenta preguntas de hoy y no las de ayer', () {
      final snap = buildDailyStreak(
        attempts: [
          point(DateTime(2026, 8, 31, 9), 12),
          point(DateTime(2026, 8, 31, 11), 8),
          point(DateTime(2026, 8, 30, 22), 50),
        ],
        dailyGoal: 40,
        now: now,
      );
      expect(snap.questionsToday, 20);
      expect(snap.testsToday, 2);
      expect(snap.progress, 0.5);
      expect(snap.goalMet, isFalse);
    });

    test('cupo cumplido si se llega al objetivo', () {
      final snap = buildDailyStreak(
        attempts: [point(now, 40)],
        dailyGoal: 40,
        now: now,
      );
      expect(snap.goalMet, isTrue);
      expect(snap.progress, 1);
    });

    test('racha de días consecutivos hasta hoy', () {
      final snap = buildDailyStreak(
        attempts: [
          point(DateTime(2026, 8, 31, 8)),
          point(DateTime(2026, 8, 30, 8)),
          point(DateTime(2026, 8, 29, 8)),
          point(DateTime(2026, 8, 27, 8)),
        ],
        dailyGoal: 40,
        now: now,
      );
      expect(snap.streakDays, 3);
      expect(snap.streakLabel, '3 días seguidos');
    });

    test('si hoy no hay test, la racha sigue si ayer sí hubo', () {
      final snap = buildDailyStreak(
        attempts: [
          point(DateTime(2026, 8, 30, 21)),
          point(DateTime(2026, 8, 29, 21)),
        ],
        dailyGoal: 40,
        now: now,
      );
      expect(snap.streakDays, 2);
      expect(snap.questionsToday, 0);
    });

    test('racha se rompe si el último día activo fue anteayer', () {
      final snap = buildDailyStreak(
        attempts: [
          point(DateTime(2026, 8, 29, 12)),
          point(DateTime(2026, 8, 28, 12)),
        ],
        dailyGoal: 40,
        now: now,
      );
      expect(snap.streakDays, 0);
    });

    test('un solo test hoy es 1 día seguido', () {
      final snap = buildDailyStreak(
        attempts: [point(now, 5)],
        dailyGoal: 40,
        now: now,
      );
      expect(snap.streakDays, 1);
      expect(snap.streakLabel, '1 día seguido');
    });
  });
}
