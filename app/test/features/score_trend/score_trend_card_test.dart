import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/features/score_trend/domain/score_trend.dart';
import 'package:opotest/features/score_trend/presentation/score_trend_card.dart';

void main() {
  testWidgets('vacío pide hacer tests', (tester) async {
    const trend = ScoreTrend(
      thisWeekAverage: null,
      previousWeekAverage: null,
      thisWeekCount: 0,
      previousWeekCount: 0,
      recentBars: [],
    );
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ScoreTrendCard(trend: trend))),
    );
    expect(find.textContaining('Haz algún test'), findsOneWidget);
  });

  testWidgets('muestra semanas y barras', (tester) async {
    final trend = ScoreTrend(
      thisWeekAverage: 80,
      previousWeekAverage: 50,
      thisWeekCount: 1,
      previousWeekCount: 2,
      recentBars: [
        ScoreTrendBar(percent: 50, finishedAt: DateTime(2026, 8, 24)),
        ScoreTrendBar(percent: 80, finishedAt: DateTime(2026, 8, 31)),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ScoreTrendCard(trend: trend))),
    );
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.textContaining('por encima'), findsOneWidget);
  });
}
