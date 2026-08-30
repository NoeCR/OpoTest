import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/features/spaced_review/domain/question_review_state.dart';
import 'package:opotest/features/spaced_review/domain/spaced_review_scheduler.dart';

void main() {
  group('SpacedReviewScheduler', () {
    final now = DateTime(2026, 8, 28, 23, 10);

    test('un fallo entra en caja 1 y toca al día siguiente', () {
      final state = SpacedReviewScheduler.afterFail(
        userId: 'u',
        testId: '1001',
        questionIndex: 0,
        now: now,
      );
      expect(state.box, 1);
      expect(state.nextDue, DateTime(2026, 8, 29));
      expect(state.lastResultCorrect, isFalse);
    });

    test('un fallo desde caja alta vuelve a caja 1', () {
      final current = QuestionReviewState(
        userId: 'u',
        testId: '1001',
        questionIndex: 0,
        box: 4,
        nextDue: DateTime(2026, 9, 10),
        lastResultCorrect: true,
      );
      final failed = SpacedReviewScheduler.afterFail(
        userId: current.userId,
        testId: current.testId,
        questionIndex: current.questionIndex,
        now: now,
      );
      expect(failed.box, 1);
      expect(failed.nextDue, DateTime(2026, 8, 29));
    });

    test('un acierto pasa a la siguiente caja y alarga el intervalo', () {
      final current = QuestionReviewState(
        userId: 'u',
        testId: '1001',
        questionIndex: 0,
        box: 1,
        nextDue: DateTime(2026, 8, 29),
        lastResultCorrect: false,
      );
      final next = SpacedReviewScheduler.afterSuccess(current, now);
      expect(next.box, 2);
      expect(next.nextDue, DateTime(2026, 8, 31));
      expect(next.lastResultCorrect, isTrue);
    });

    test('en la última caja un acierto mantiene la caja 5 a 30 días', () {
      final current = QuestionReviewState(
        userId: 'u',
        testId: '1001',
        questionIndex: 0,
        box: 5,
        nextDue: DateTime(2026, 8, 28),
        lastResultCorrect: true,
      );
      final next = SpacedReviewScheduler.afterSuccess(current, now);
      expect(next.box, 5);
      expect(next.nextDue, DateTime(2026, 9, 27));
    });

    test('isDue usa el día calendario', () {
      final state = QuestionReviewState(
        userId: 'u',
        testId: '1001',
        questionIndex: 0,
        box: 1,
        nextDue: DateTime(2026, 8, 28),
        lastResultCorrect: false,
      );
      expect(SpacedReviewScheduler.isDue(state, DateTime(2026, 8, 28, 8)), isTrue);
      expect(SpacedReviewScheduler.isDue(state, DateTime(2026, 8, 27, 23)), isFalse);
      expect(SpacedReviewScheduler.isDue(state, DateTime(2026, 8, 29, 0)), isTrue);
    });
  });
}
