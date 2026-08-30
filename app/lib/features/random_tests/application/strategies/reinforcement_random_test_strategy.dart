import '../../../../models/question.dart';
import '../../../failed_questions_export/domain/fail_resolution.dart';
import '../../../spaced_review/domain/question_review_state.dart';
import '../../domain/random_test_constants.dart';
import '../../domain/random_test_mode.dart';
import '../../domain/random_test_pick.dart';
import '../../domain/random_test_strategy.dart';
import '../random_test_context.dart';
import '../synthetic_test_builder.dart';

class ReinforcementRandomTestStrategy implements RandomTestStrategy {
  ReinforcementRandomTestStrategy({
    SyntheticTestBuilder? builder,
    DateTime? now,
  })  : _builder = builder ?? SyntheticTestBuilder(),
        _now = now;

  final SyntheticTestBuilder _builder;
  final DateTime? _now;

  @override
  RandomTestMode get mode => RandomTestMode.reinforcement;

  @override
  Future<RandomTestPick> pick(RandomTestContext context, String userId) async {
    final now = _now ?? DateTime.now();
    final due = await context.db.dueQuestionReviews(userId, now);
    if (due.isNotEmpty) {
      return _pickFromDue(context, due);
    }
    return _pickLegacyFails(context, userId);
  }

  Future<RandomTestPick> _pickFromDue(
    RandomTestContext context,
    List<QuestionReviewState> due,
  ) async {
    final selected = <Question>[];
    final testCache = <String, TestDefinition?>{};
    final shuffled = List.of(due)..shuffle(context.random);

    for (final state in shuffled) {
      if (selected.length >= RandomTestConstants.reinforcementQuestionCap) break;
      final test = testCache[state.testId] ??= await context.db.getTest(state.testId);
      if (test == null) continue;
      if (state.questionIndex < 0 || state.questionIndex >= test.questions.length) continue;
      selected.add(
        cloneQuestion(
          test.questions[state.questionIndex],
          order: selected.length + 1,
          sourceTestId: state.testId,
          sourceQuestionIndex: state.questionIndex,
        ),
      );
    }

    if (selected.isEmpty) return context.emptyFor(mode);
    return _builder.build(
      idPrefix: 'reinforcement_random',
      namePrefix: 'Test de refuerzo',
      type: 'reinforcement',
      questions: renumberQuestions(selected),
    );
  }

  Future<RandomTestPick> _pickLegacyFails(RandomTestContext context, String userId) async {
    final attempts = await context.db.attemptsForUserModel(userId);
    final recent = attempts
        .where((attempt) => !RandomTestConstants.isSyntheticAttemptTestId(attempt.testId))
        .take(RandomTestConstants.reinforcementMaxAttempts)
        .toList();

    if (recent.isEmpty) return context.emptyFor(mode);

    final seen = FailResolution(await context.db.recoveredQuestionsForUser(userId));
    final failed = <Question>[];
    final testCache = <String, TestDefinition?>{};

    for (final attempt in recent) {
      final test = testCache[attempt.testId] ??= await context.db.getTest(attempt.testId);
      if (test == null) continue;

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

        failed.add(
          cloneQuestion(
            test.questions[i],
            order: failed.length + 1,
            sourceTestId: attempt.testId,
            sourceQuestionIndex: i,
          ),
        );
      }
    }

    if (failed.isEmpty) return context.emptyFor(mode);

    failed.shuffle(context.random);
    final cap = failed.length > RandomTestConstants.reinforcementMinIfNoneDue
        ? RandomTestConstants.reinforcementMinIfNoneDue
        : failed.length;
    final selected = renumberQuestions(failed.take(cap).toList());

    return _builder.build(
      idPrefix: 'reinforcement_random',
      namePrefix: 'Test de refuerzo',
      type: 'reinforcement',
      questions: selected,
    );
  }
}
