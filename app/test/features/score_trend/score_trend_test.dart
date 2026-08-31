import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/features/score_trend/domain/score_trend.dart';

void main() {
  final now = DateTime(2026, 8, 31, 12); // lunes

  AttemptScorePoint p(DateTime at, double percent, {String id = '1001'}) =>
      AttemptScorePoint(finishedAt: at, percent: percent, testId: id);

  test('vacío sin intentos', () {
    final trend = buildScoreTrend(attempts: const [], now: now);
    expect(trend.isEmpty, isTrue);
    expect(trend.weekDelta, isNull);
  });

  test('ignora tests sintéticos', () {
    final trend = buildScoreTrend(
      attempts: [
        p(now, 90, id: 'mixed_random_1'),
        p(now, 40, id: 'simulacrum_random_1'),
        p(now, 80, id: '1001'),
      ],
      now: now,
    );
    expect(trend.thisWeekCount, 1);
    expect(trend.thisWeekAverage, 80);
    expect(trend.recentBars.single.percent, 80);
  });

  test('separa esta semana y la anterior (lunes a domingo)', () {
    final trend = buildScoreTrend(
      attempts: [
        p(DateTime(2026, 8, 31, 10), 80),
        p(DateTime(2026, 8, 24, 10), 60),
        p(DateTime(2026, 8, 30, 10), 40),
      ],
      now: now,
    );
    expect(trend.thisWeekCount, 1);
    expect(trend.thisWeekAverage, 80);
    expect(trend.previousWeekCount, 2);
    expect(trend.previousWeekAverage, 50);
    expect(trend.weekDelta, 30);
  });

  test('recorta a los últimos 15 en orden cronológico', () {
    final attempts = [
      for (var i = 1; i <= 20; i++)
        p(DateTime(2026, 8, i, 10), i.toDouble()),
    ];
    final trend = buildScoreTrend(attempts: attempts, now: now, maxBars: 15);
    expect(trend.recentBars, hasLength(15));
    expect(trend.recentBars.first.percent, 6);
    expect(trend.recentBars.last.percent, 20);
  });
}
