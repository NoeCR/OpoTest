import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/features/daily_focus/domain/daily_focus.dart';
import 'package:opotest/features/random_tests/domain/random_test_mode.dart';

void main() {
  group('isRecentMark', () {
    final now = DateTime(2026, 8, 27, 12);

    test('acepta marcas de hoy y de hace 30 días', () {
      expect(isRecentMark(now, now), isTrue);
      expect(isRecentMark(now.subtract(const Duration(days: 30)), now), isTrue);
      expect(isRecentMark(now.add(const Duration(minutes: 5)), now), isTrue);
    });

    test('rechaza marcas de hace 31 días', () {
      expect(isRecentMark(now.subtract(const Duration(days: 31)), now), isFalse);
    });
  });

  group('countsForMarkedFocus', () {
    final now = DateTime(2026, 8, 28, 12);

    test('cuenta marcas recientes si no hay repaso', () {
      expect(
        countsForMarkedFocus(
          markedAt: now.subtract(const Duration(days: 2)),
          now: now,
        ),
        isTrue,
      );
    });

    test('no cuenta marcas ya cubiertas por un repaso de hoy', () {
      expect(
        countsForMarkedFocus(
          markedAt: now.subtract(const Duration(hours: 3)),
          now: now,
          lastMarkedReviewAt: now.subtract(const Duration(hours: 1)),
        ),
        isFalse,
      );
    });

    test('sí cuenta marcas nuevas posteriores al repaso de hoy', () {
      expect(
        countsForMarkedFocus(
          markedAt: now.subtract(const Duration(minutes: 10)),
          now: now,
          lastMarkedReviewAt: now.subtract(const Duration(hours: 1)),
        ),
        isTrue,
      );
    });

    test('un repaso de ayer no descarta las marcas de hoy', () {
      expect(
        countsForMarkedFocus(
          markedAt: now.subtract(const Duration(days: 2)),
          now: now,
          lastMarkedReviewAt: now.subtract(const Duration(days: 1)),
        ),
        isTrue,
      );
    });
  });

  group('pickWeakestTest', () {
    test('elige el peor último porcentaje', () {
      final picked = pickWeakestTest(const [
        WeakTestHint(testId: 'a', testName: 'A', lastPercent: 80, attempts: 1),
        WeakTestHint(testId: 'b', testName: 'B', lastPercent: 40, attempts: 1),
        WeakTestHint(testId: 'c', testName: 'C', lastPercent: 100, attempts: 5),
      ]);
      expect(picked?.testId, 'b');
    });

    test('en empate de % prioriza más intentos', () {
      final picked = pickWeakestTest(const [
        WeakTestHint(testId: 'a', testName: 'A', lastPercent: 50, attempts: 1),
        WeakTestHint(testId: 'b', testName: 'B', lastPercent: 50, attempts: 4),
      ]);
      expect(picked?.testId, 'b');
    });

    test('ignora tests al 100%', () {
      expect(
        pickWeakestTest(const [
          WeakTestHint(testId: 'a', testName: 'A', lastPercent: 100, attempts: 2),
        ]),
        isNull,
      );
    });
  });

  group('buildDailyFocus prioridad', () {
    const weakest = WeakTestHint(
      testId: 'weak-1',
      testName: 'Constitución T1',
      lastPercent: 45,
      attempts: 3,
    );
    const last = LastAttemptHint(testId: 'last-1', testName: 'Último test');

    test('sin temario pide importar', () {
      final plan = buildDailyFocus(const DailyFocusSnapshot(contentReady: false));
      expect(plan.primary.kind, DailyFocusKind.getStarted);
      expect(plan.primary.reason, contains('cualquier ley'));
      expect(plan.secondary, isEmpty);
    });

    test('con temario y sin datos propone azar', () {
      final plan = buildDailyFocus(const DailyFocusSnapshot(contentReady: true));
      expect(plan.primary.kind, DailyFocusKind.classic);
      expect(plan.primary.randomMode, RandomTestMode.classic);
      expect(plan.primary.reason, contains('cualquier ley'));
    });

    test('marcas ganan a fallos y al test flojo', () {
      final plan = buildDailyFocus(
        const DailyFocusSnapshot(
          contentReady: true,
          recentMarkedCount: 3,
          recentFailCount: 8,
          weakest: weakest,
          lastAttempt: last,
        ),
      );
      expect(plan.primary.kind, DailyFocusKind.markedReview);
      expect(plan.primary.randomMode, RandomTestMode.markedReview);
      expect(plan.secondary.map((a) => a.kind), [
        DailyFocusKind.reinforcement,
        DailyFocusKind.weakTest,
      ]);
    });

    test('sin marcas, fallos ganan al test flojo', () {
      final plan = buildDailyFocus(
        const DailyFocusSnapshot(
          contentReady: true,
          recentFailCount: 2,
          weakest: weakest,
        ),
      );
      expect(plan.primary.kind, DailyFocusKind.reinforcement);
      expect(plan.primary.randomMode, RandomTestMode.reinforcement);
      expect(plan.secondary.single.kind, DailyFocusKind.weakTest);
      expect(plan.secondary.single.testId, 'weak-1');
    });

    test('sin marcas ni fallos usa el test más flojo', () {
      final plan = buildDailyFocus(
        const DailyFocusSnapshot(contentReady: true, weakest: weakest),
      );
      expect(plan.primary.kind, DailyFocusKind.weakTest);
      expect(plan.primary.testId, 'weak-1');
      expect(plan.primary.reason, contains('45%'));
      expect(plan.secondary, isEmpty);
    });

    test('si solo hay último intento, reintenta', () {
      final plan = buildDailyFocus(
        const DailyFocusSnapshot(contentReady: true, lastAttempt: last),
      );
      expect(plan.primary.kind, DailyFocusKind.retryLast);
      expect(plan.primary.testId, 'last-1');
    });

    test('no usa último intento si ya hay otra propuesta', () {
      final plan = buildDailyFocus(
        const DailyFocusSnapshot(
          contentReady: true,
          recentFailCount: 1,
          lastAttempt: last,
        ),
      );
      expect(plan.primary.kind, DailyFocusKind.reinforcement);
      expect(plan.secondary, isEmpty);
    });
  });
}
