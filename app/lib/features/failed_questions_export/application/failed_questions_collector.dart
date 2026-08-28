import '../../../database/app_database.dart';
import '../../../models/question.dart';
import '../../random_tests/domain/random_test_constants.dart';
import '../domain/failed_question_item.dart';
import '../domain/failed_questions_range.dart';
import '../domain/fail_resolution.dart';

class FailedQuestionsCollector {
  FailedQuestionsCollector(this._db);

  final AppDatabase _db;

  Future<FailedQuestionsCollectResult> collect({
    required String userId,
    required FailedQuestionsRange range,
  }) async {
    final attempts = await _db.attemptsForUserModel(userId);
    final laws = {
      for (final row in await _db.getLaws())
        row['id'] as String: (
          code: row['code']?.toString() ?? '',
          name: row['name']?.toString() ?? '',
        ),
    };

    final testCache = <String, TestDefinition?>{};
    final lawIdCache = <String, String?>{};
    final titleCache = <String, String?>{};
    final seen = FailResolution(await _db.recoveredQuestionsForUser(userId));
    final items = <FailedQuestionItem>[];
    var skippedMissingTests = 0;

    for (final attempt in attempts) {
      if (RandomTestConstants.isSyntheticAttemptTestId(attempt.testId)) continue;
      if (!range.contains(attempt.finishedAt)) continue;

      final test = testCache[attempt.testId] ??= await _db.getTest(attempt.testId);
      if (test == null) {
        skippedMissingTests += _failedCount(attempt.answers, const []);
        continue;
      }

      for (var i = 0; i < test.questions.length; i++) {
        final answer = attempt.answers[i];
        if (answer == null || answer == 0) continue;
        final correct = answer == test.questions[i].solution;
        if (!seen.isCurrentFail(
          testId: attempt.testId,
          questionIndex: i,
          correct: correct,
          at: attempt.finishedAt,
        )) {
          continue;
        }

        final lawId = lawIdCache[attempt.testId] ??= await _db.getTestLawId(attempt.testId);
        final law = laws[lawId];
        titleCache[attempt.testId] ??= await _db.getTitleNameForTest(attempt.testId);

        items.add(
          FailedQuestionItem(
            testId: attempt.testId,
            testName: attempt.testName.isNotEmpty ? attempt.testName : test.name,
            questionIndex: i,
            question: test.questions[i],
            userAnswer: answer,
            failedAt: attempt.finishedAt,
            lawCode: law?.code ?? '',
            lawName: law?.name ?? '',
            titleName: titleCache[attempt.testId],
          ),
        );
      }
    }

    return FailedQuestionsCollectResult(
      items: items,
      skippedMissingTests: skippedMissingTests,
    );
  }

  int _failedCount(Map<int, int> answers, List<Question> questions) {
    if (questions.isEmpty) {
      return answers.values.where((a) => a != 0).length;
    }
    var n = 0;
    for (var i = 0; i < questions.length; i++) {
      final answer = answers[i];
      if (answer == null || answer == 0) continue;
      if (answer != questions[i].solution) n++;
    }
    return n;
  }
}
