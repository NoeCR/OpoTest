import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/features/in_progress_session/domain/in_progress_choices.dart';
import 'package:opotest/features/in_progress_session/domain/in_progress_session.dart';
import 'package:opotest/features/in_progress_session/presentation/in_progress_session_dialogs.dart';
import 'package:opotest/models/question.dart';

import '../../helpers/database_helper.dart';

void main() {
  testWidgets('el diálogo de pausa ofrece Pausar y Finalizar', (tester) async {
    late InProgressLeaveChoice choice;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                choice = await showInProgressLeaveDialog(context, hasAnswers: true);
              },
              child: const Text('abrir'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('¿Pausar el test?'), findsOneWidget);
    expect(find.text('Pausar'), findsOneWidget);
    expect(find.text('Finalizar'), findsOneWidget);

    await tester.tap(find.text('Pausar'));
    await tester.pumpAndSettle();
    expect(choice, InProgressLeaveChoice.pause);
  });

  testWidgets('sin respuestas el diálogo de pausa ofrece Salir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => showInProgressLeaveDialog(context, hasAnswers: false),
              child: const Text('abrir'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Salir'), findsOneWidget);
    expect(find.text('Finalizar'), findsNothing);
  });

  testWidgets('el diálogo de conflicto ofrece reanudar o sustituir', (tester) async {
    late InProgressStartChoice choice;
    final existing = InProgressSession.fromLive(
      userId: 'u',
      test: TestDefinition.fromApiJson(sampleTestJson(name: 'Constitución T1')),
      answers: const {0: 1},
      currentIndex: 2,
      elapsedSeconds: 40,
      errorFormat: 100,
      durationMinutes: 0,
      examSimulation: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                choice = await showInProgressConflictDialog(context, existing: existing);
              },
              child: const Text('abrir'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Tienes un test a medias'), findsOneWidget);
    expect(find.textContaining('Constitución T1'), findsOneWidget);

    await tester.tap(find.text('Empezar este'));
    await tester.pumpAndSettle();
    expect(choice, InProgressStartChoice.replace);
  });
}
