import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/features/in_progress_session/domain/in_progress_session.dart';
import 'package:opotest/models/question.dart';

import '../../helpers/database_helper.dart';

void main() {
  group('InProgressSession', () {
    test('roundtrip mapa conserva respuestas, índice y snapshot del test', () {
      final test = TestDefinition.fromApiJson(
        sampleTestJson(id: 'mixed_random_1', name: 'Mixto · 4 preguntas', questionCount: 4),
      );
      final session = InProgressSession.fromLive(
        userId: 'user-1',
        test: test,
        answers: const {0: 2, 2: 1},
        currentIndex: 2,
        elapsedSeconds: 95,
        errorFormat: 50,
        durationMinutes: 20,
        examSimulation: true,
        updatedAt: DateTime.parse('2026-08-27T10:15:00'),
      );

      final restored = InProgressSession.fromMap(session.toMap());
      expect(restored.userId, 'user-1');
      expect(restored.testId, 'mixed_random_1');
      expect(restored.testName, 'Mixto · 4 preguntas');
      expect(restored.answers, {0: 2, 2: 1});
      expect(restored.currentIndex, 2);
      expect(restored.elapsedSeconds, 95);
      expect(restored.errorFormat, 50);
      expect(restored.durationMinutes, 20);
      expect(restored.examSimulation, isTrue);
      expect(restored.questionCount, 4);
      expect(restored.test.questions.map((q) => q.text).toList(), test.questions.map((q) => q.text).toList());
      expect(restored.test.questions.first.solution, test.questions.first.solution);
    });

    test('progressLabel resume pregunta y reloj', () {
      final session = InProgressSession.fromLive(
        userId: 'u',
        test: TestDefinition.fromApiJson(sampleTestJson(questionCount: 20)),
        answers: const {},
        currentIndex: 4,
        elapsedSeconds: 75,
        errorFormat: 100,
        durationMinutes: 0,
        examSimulation: false,
      );
      expect(session.progressLabel, 'Pregunta 5 de 20 · 01:15');
      expect(session.answeredCount, 0);
    });

    test('payload corrupto no rompe fromMap', () {
      final restored = InProgressSession.fromMap({
        'user_id': 'u',
        'test_id': 'x',
        'test_name': 'Roto',
        'payload': 'no-json',
        'answers_json': 'tampoco',
        'current_index': 0,
        'elapsed_seconds': 0,
        'error_format': 0,
        'duration_minutes': 0,
        'exam_simulation': 0,
        'question_count': 0,
        'updated_at': 'no-fecha',
      });
      expect(restored.test.questions, isEmpty);
      expect(restored.answers, isEmpty);
    });
  });

  group('formatTestClock', () {
    test('formatea minutos y segundos', () {
      expect(formatTestClock(0), '00:00');
      expect(formatTestClock(5), '00:05');
      expect(formatTestClock(75), '01:15');
      expect(formatTestClock(-3), '00:00');
    });
  });
}
