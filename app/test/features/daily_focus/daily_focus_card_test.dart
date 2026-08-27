import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/features/daily_focus/domain/daily_focus.dart';
import 'package:opotest/features/daily_focus/presentation/daily_focus_card.dart';
import 'package:opotest/features/random_tests/domain/random_test_mode.dart';

void main() {
  testWidgets('muestra título, razón y secundarias', (tester) async {
    DailyFocusAction? selected;
    const plan = DailyFocusPlan(
      primary: DailyFocusAction(
        kind: DailyFocusKind.markedReview,
        title: 'Repasar marcas',
        reason: 'Tienes 3 preguntas marcadas para revisión',
        randomMode: RandomTestMode.markedReview,
      ),
      secondary: [
        DailyFocusAction(
          kind: DailyFocusKind.reinforcement,
          title: 'Repasar fallos',
          reason: 'Tienes 2 fallos de los últimos 7 días',
          randomMode: RandomTestMode.reinforcement,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyFocusCard(
            plan: plan,
            onSelect: (action) => selected = action,
          ),
        ),
      ),
    );

    expect(find.text('HOY'), findsOneWidget);
    expect(find.text('Repasar marcas'), findsOneWidget);
    expect(find.text('Tienes 3 preguntas marcadas para revisión'), findsOneWidget);
    expect(find.text('Repasar fallos'), findsOneWidget);

    await tester.tap(find.text('Empezar'));
    expect(selected?.kind, DailyFocusKind.markedReview);
  });
}
