import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/features/random_tests/domain/official_paper_ref.dart';
import 'package:opotest/features/random_tests/presentation/simulacrum_screen.dart';
import 'package:opotest/services/test_preferences.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const madrid = OfficialPaperRef(
    id: 'paper_am',
    name: 'TAI Ayuntamiento de Madrid 2025',
    administration: 'Ayuntamiento de Madrid',
    year: 2025,
  );
  const inap = OfficialPaperRef(
    id: 'paper_inap',
    name: 'TAI INAP 2024 · Ingreso libre modelo A',
    administration: 'INAP / AGE',
    year: 2024,
  );

  Future<TestPreferences> pumpScreen(
    WidgetTester tester, {
    required List<OfficialPaperRef> papers,
    TestPreferences? prefs,
  }) async {
    final resolved = prefs ?? TestPreferences();
    if (prefs == null) {
      SharedPreferences.setMockInitialValues({});
    }
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: resolved,
        child: MaterialApp(home: SimulacrumScreen(initialPapers: papers)),
      ),
    );
    await tester.pump();
    return resolved;
  }

  testWidgets('muestra opciones guardadas y el botón de empezar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = TestPreferences();
    await prefs.setSimulacrumQuestions(50);
    await prefs.setSimulacrumMinutes(60);

    await pumpScreen(tester, papers: [madrid], prefs: prefs);

    expect(find.text('Simulacro'), findsWidgets);
    expect(find.textContaining('pruebas de convocatoria'), findsOneWidget);
    expect(find.textContaining('Los fallos restan 1 acierto'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);
    expect(find.text('Empezar · 50 preguntas · 60 min'), findsOneWidget);

    await tester.tap(find.text('100'));
    await tester.pump();
    expect(prefs.simulacrumQuestions, 100);
    expect(find.text('Empezar · 100 preguntas · 60 min'), findsOneWidget);
  });

  testWidgets('lista pruebas por administración y permite excluirlas', (tester) async {
    final prefs = await pumpScreen(tester, papers: [madrid, inap]);

    expect(find.text('2 de 2 seleccionadas'), findsOneWidget);
    expect(find.text('Ayuntamiento de Madrid'), findsOneWidget);
    expect(find.text('INAP / AGE'), findsOneWidget);
    expect(find.text('TAI Ayuntamiento de Madrid 2025'), findsOneWidget);

    await tester.ensureVisible(find.text('Ninguna'));
    await tester.tap(find.text('Ninguna'));
    await tester.pump();
    expect(find.text('0 de 2 seleccionadas'), findsOneWidget);
    expect(find.text('Selecciona al menos una prueba'), findsOneWidget);
    expect(prefs.isSimulacrumPaperIncluded('paper_am'), isFalse);

    await tester.ensureVisible(find.text('INAP / AGE'));
    await tester.tap(find.text('INAP / AGE'));
    await tester.pump();
    expect(find.text('1 de 2 seleccionadas'), findsOneWidget);
    expect(prefs.isSimulacrumPaperIncluded('paper_inap'), isTrue);
    expect(prefs.isSimulacrumPaperIncluded('paper_am'), isFalse);

    await tester.ensureVisible(find.text('Todas'));
    await tester.tap(find.text('Todas'));
    await tester.pump();
    expect(find.text('2 de 2 seleccionadas'), findsOneWidget);
    expect(find.text('Empezar · 100 preguntas · 90 min'), findsOneWidget);
  });
}
