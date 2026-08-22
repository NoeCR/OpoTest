import '../../../models/question.dart';

class RandomTestPick {
  const RandomTestPick.test(this.testId)
      : mixedTest = null,
        emptyMessage = null;

  const RandomTestPick.mixed(this.mixedTest)
      : testId = null,
        emptyMessage = null;

  const RandomTestPick.empty(this.emptyMessage)
      : testId = null,
        mixedTest = null;

  final String? testId;
  final TestDefinition? mixedTest;
  final String? emptyMessage;

  bool get isEmpty => emptyMessage != null;
}
