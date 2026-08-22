import '../../../../models/question.dart';
import '../../domain/random_test_constants.dart';
import '../../domain/random_test_mode.dart';
import '../../domain/random_test_pick.dart';
import '../../domain/random_test_strategy.dart';
import '../random_test_context.dart';
import '../synthetic_test_builder.dart';

class MarkedReviewRandomTestStrategy implements RandomTestStrategy {
  MarkedReviewRandomTestStrategy({SyntheticTestBuilder? builder})
      : _builder = builder ?? SyntheticTestBuilder();

  final SyntheticTestBuilder _builder;

  @override
  RandomTestMode get mode => RandomTestMode.markedReview;

  @override
  Future<RandomTestPick> pick(RandomTestContext context, String userId) async {
    final marked = await context.db.markedQuestionsForUser(userId);
    if (marked.isEmpty) return context.emptyFor(mode);

    final selected = <Question>[];
    for (final item in marked) {
      if (RandomTestConstants.isSyntheticAttemptTestId(item.testId)) continue;
      final test = await context.db.getTest(item.testId);
      if (test == null) continue;
      if (item.questionIndex < 0 || item.questionIndex >= test.questions.length) continue;
      selected.add(cloneQuestion(test.questions[item.questionIndex], order: selected.length + 1));
    }

    if (selected.isEmpty) return context.emptyFor(mode);

    return _builder.build(
      idPrefix: 'review_random',
      namePrefix: 'Test de repaso',
      type: 'review',
      questions: selected,
    );
  }
}
