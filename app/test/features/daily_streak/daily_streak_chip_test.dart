import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/features/daily_streak/domain/daily_streak.dart';
import 'package:opotest/features/daily_streak/presentation/daily_streak_chip.dart';

void main() {
  testWidgets('muestra racha, cupo y barra', (tester) async {
    var tapped = false;
    const snapshot = DailyStreakSnapshot(
      streakDays: 4,
      questionsToday: 12,
      testsToday: 1,
      dailyGoal: 40,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyStreakChip(
            snapshot: snapshot,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('4 días seguidos'), findsOneWidget);
    expect(find.text('12 / 40 preguntas hoy'), findsOneWidget);
    expect(find.text('Cupo de hoy cumplido'), findsNothing);

    await tester.tap(find.byType(DailyStreakChip));
    expect(tapped, isTrue);
  });

  testWidgets('marca el cupo cumplido', (tester) async {
    const snapshot = DailyStreakSnapshot(
      streakDays: 1,
      questionsToday: 40,
      testsToday: 2,
      dailyGoal: 40,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DailyStreakChip(snapshot: snapshot),
        ),
      ),
    );

    expect(find.text('1 día seguido'), findsOneWidget);
    expect(find.text('Cupo de hoy cumplido'), findsOneWidget);
  });
}
