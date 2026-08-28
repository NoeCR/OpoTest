import '../../../../models/question.dart';
import '../../domain/random_test_constants.dart';
import '../../domain/random_test_mode.dart';
import '../../domain/random_test_pick.dart';
import '../../domain/random_test_strategy.dart';
import '../random_test_context.dart';
import '../synthetic_test_builder.dart';

class MixedRandomTestStrategy implements RandomTestStrategy {
  MixedRandomTestStrategy({
    this.questionCount = RandomTestConstants.mixedQuestionCount,
    this.idPrefix = 'mixed_random',
    this.namePrefix = 'Test mixto',
    this.type = 'mixed',
    this.emptyHint,
    this.allowedTypes,
    this.allowedTestIds,
    SyntheticTestBuilder? builder,
  }) : _builder = builder ?? SyntheticTestBuilder();

  final int questionCount;
  final String idPrefix;
  final String namePrefix;
  final String type;
  final String? emptyHint;
  final List<String>? allowedTypes;
  /// Si no es null, el mixto solo toma preguntas de estos tests.
  final Set<String>? allowedTestIds;
  final SyntheticTestBuilder _builder;

  @override
  RandomTestMode get mode => RandomTestMode.mixed;

  RandomTestPick _empty(RandomTestContext context) {
    return RandomTestPick.empty(emptyHint ?? mode.emptyHint);
  }

  @override
  Future<RandomTestPick> pick(RandomTestContext context, String userId) async {
    var meta = await context.db.getOfficialTestsMeta(types: allowedTypes);
    if (allowedTestIds != null) {
      meta = meta.where((row) => allowedTestIds!.contains(row.id)).toList();
    }
    if (meta.isEmpty) return _empty(context);

    final target = questionCount < 1 ? RandomTestConstants.mixedQuestionCount : questionCount;
    final selected = <Question>[];
    final usedKeys = <String>{};
    final usedLaws = <String>{};
    final cache = <String, TestDefinition?>{};

    Future<TestDefinition?> testOf(String id) async {
      if (cache.containsKey(id)) return cache[id];
      final test = await context.db.getTest(id);
      cache[id] = test;
      return test;
    }

    bool tryAdd(TestDefinition test, int index) {
      if (index < 0 || index >= test.questions.length) return false;
      final key = '${test.id}:$index';
      if (!usedKeys.add(key)) return false;
      final q = test.questions[index];
      selected.add(
        cloneQuestion(
          q,
          order: selected.length + 1,
          sourceTestId: test.id,
          sourceQuestionIndex: index,
        ),
      );
      return true;
    }

    final shuffled = List.of(meta)..shuffle(context.random);
    for (final row in shuffled) {
      if (selected.length >= target) break;
      final lawId = row.lawId;
      if (lawId.isNotEmpty && usedLaws.contains(lawId) && usedLaws.length >= 3) {
        continue;
      }
      final test = await testOf(row.id);
      if (test == null || test.questions.isEmpty) continue;
      final index = context.random.nextInt(test.questions.length);
      if (!tryAdd(test, index)) continue;
      if (lawId.isNotEmpty) usedLaws.add(lawId);
    }

    if (selected.length < target) {
      final fill = List.of(meta)..shuffle(context.random);
      for (final row in fill) {
        if (selected.length >= target) break;
        final test = await testOf(row.id);
        if (test == null || test.questions.isEmpty) continue;
        final indices = [for (var i = 0; i < test.questions.length; i++) i]..shuffle(context.random);
        for (final index in indices) {
          if (selected.length >= target) break;
          tryAdd(test, index);
        }
      }
    }

    if (selected.isEmpty) return _empty(context);

    return _builder.build(
      idPrefix: idPrefix,
      namePrefix: namePrefix,
      type: type,
      questions: selected,
    );
  }
}
