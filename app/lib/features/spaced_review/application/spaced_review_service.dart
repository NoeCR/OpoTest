import '../../../database/app_database.dart';
import '../../../models/question.dart';
import '../../random_tests/domain/random_test_constants.dart';
import '../domain/question_review_state.dart';
import '../domain/spaced_review_scheduler.dart';

class SpacedReviewService {
  SpacedReviewService(this._db);

  final AppDatabase _db;

  Future<void> applyFromTest({
    required String userId,
    required TestDefinition test,
    required Map<int, int> answers,
    required DateTime at,
  }) async {
    final existing = {
      for (final state in await _db.questionReviewsForUser(userId)) state.key: state,
    };
    final updates = <QuestionReviewState>[];

    for (var i = 0; i < test.questions.length; i++) {
      final question = test.questions[i];
      final answer = answers[i];
      if (answer == null || answer == 0) continue;

      final originId = question.sourceTestId ?? test.id;
      final originIndex = question.sourceQuestionIndex ?? i;
      if (originId.isEmpty || RandomTestConstants.isSyntheticAttemptTestId(originId)) {
        continue;
      }

      final key = QuestionReviewState.keyOf(originId, originIndex);
      final current = existing[key];
      final correct = answer == question.solution;
      if (!correct) {
        updates.add(
          SpacedReviewScheduler.afterFail(
            userId: userId,
            testId: originId,
            questionIndex: originIndex,
            now: at,
          ),
        );
      } else if (current != null) {
        updates.add(SpacedReviewScheduler.afterSuccess(current, at));
      }
    }

    await _db.upsertQuestionReviews(updates);
  }

  Future<int> countDue({required String userId, DateTime? now}) {
    return _db.countDueQuestionReviews(userId, now ?? DateTime.now());
  }
}
