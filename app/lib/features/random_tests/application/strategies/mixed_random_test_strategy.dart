import '../../../../models/question.dart';
import '../../domain/random_test_constants.dart';
import '../../domain/random_test_mode.dart';
import '../../domain/random_test_pick.dart';
import '../../domain/random_test_strategy.dart';
import '../random_test_context.dart';
import '../synthetic_test_builder.dart';

class MixedRandomTestStrategy implements RandomTestStrategy {
  MixedRandomTestStrategy({SyntheticTestBuilder? builder})
      : _builder = builder ?? SyntheticTestBuilder();

  final SyntheticTestBuilder _builder;

  @override
  RandomTestMode get mode => RandomTestMode.mixed;

  @override
  Future<RandomTestPick> pick(RandomTestContext context, String userId) async {
    final meta = await context.db.getOfficialTestsMeta();
    if (meta.isEmpty) return context.emptyFor(mode);

    final shuffled = List.of(meta)..shuffle(context.random);
    final selected = <Question>[];
    final usedLaws = <String>{};

    for (final row in shuffled) {
      if (selected.length >= RandomTestConstants.mixedQuestionCount) break;
      final lawId = row.lawId;
      if (lawId.isNotEmpty && usedLaws.contains(lawId) && usedLaws.length >= 3) {
        continue;
      }

      final test = await context.db.getTest(row.id);
      if (test == null || test.questions.isEmpty) continue;

      final q = test.questions[context.random.nextInt(test.questions.length)];
      selected.add(cloneQuestion(q, order: selected.length + 1));
      if (lawId.isNotEmpty) usedLaws.add(lawId);
    }

    while (selected.length < RandomTestConstants.mixedQuestionCount && meta.isNotEmpty) {
      final row = meta[context.random.nextInt(meta.length)];
      final test = await context.db.getTest(row.id);
      if (test == null || test.questions.isEmpty) continue;
      final q = test.questions[context.random.nextInt(test.questions.length)];
      selected.add(cloneQuestion(q, order: selected.length + 1));
    }

    if (selected.isEmpty) return context.emptyFor(mode);

    return _builder.build(
      idPrefix: 'mixed_random',
      namePrefix: 'Test mixto',
      type: 'mixed',
      questions: selected,
    );
  }
}
