import '../../../models/question.dart';
import '../domain/random_test_pick.dart';

/// Builder para tests sintéticos generados al vuelo (mixto, refuerzo, repaso).
class SyntheticTestBuilder {
  SyntheticTestBuilder({int? timestampMs})
      : _timestampMs = timestampMs ?? DateTime.now().millisecondsSinceEpoch;

  final int _timestampMs;

  RandomTestPick build({
    required String idPrefix,
    required String namePrefix,
    required String type,
    required List<Question> questions,
  }) {
    return RandomTestPick.mixed(
      TestDefinition(
        id: '${idPrefix}_$_timestampMs',
        name: '$namePrefix · ${questions.length} preguntas',
        type: type,
        questions: questions,
      ),
    );
  }
}

Question cloneQuestion(Question source, {required int order}) {
  return Question(
    order: order,
    text: source.text,
    answers: source.answers,
    solution: source.solution,
    clarificationHtml: source.clarificationHtml,
  );
}

List<Question> renumberQuestions(List<Question> questions) {
  return [
    for (var i = 0; i < questions.length; i++)
      cloneQuestion(questions[i], order: i + 1),
  ];
}
