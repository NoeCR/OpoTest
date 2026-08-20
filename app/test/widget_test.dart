import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testea_local/models/test_stats.dart';
import 'package:testea_local/widgets/score_stars.dart';
import 'package:testea_local/widgets/test_picker_card.dart';

void main() {
  group('ScoreStars widget', () {
    testWidgets('renderiza 5 iconos de estrella', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScoreStars(percent: 80),
          ),
        ),
      );

      expect(find.byIcon(Icons.star_rounded), findsWidgets);
      expect(find.byIcon(Icons.star_outline_rounded), findsWidgets);
    });
  });

  group('TestPickerCard widget', () {
    testWidgets('muestra badge 100% en intento perfecto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 200,
              child: TestPickerCard(
                index: 1,
                stats: const TestStats(lastPercent: 100, bestPercent: 100, attempts: 2),
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Último intento'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('muestra estado sin realizar sin intentos', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 200,
              child: TestPickerCard(
                index: 3,
                stats: const TestStats(),
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Sin realizar'), findsOneWidget);
      expect(find.text('Nuevo'), findsOneWidget);
    });

    testWidgets('semantics describe último intento y estadísticas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 200,
              child: TestPickerCard(
                index: 5,
                stats: const TestStats(
                  lastPercent: 75,
                  bestPercent: 90,
                  avgPercent: 70,
                  attempts: 3,
                ),
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(TestPickerCard));
      expect(
        semantics.label,
        contains('Test 05'),
      );
      expect(semantics.label, contains('75%'));
    });
  });
}
