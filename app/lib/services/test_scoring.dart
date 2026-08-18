import '../models/question.dart';

class TestScoring {
  static Result score({
    required List<Question> questions,
    required Map<int, int> answers,
    required int errorFormat,
  }) {
    var correct = 0;
    var incorrect = 0;
    var answered = 0;
    for (var i = 0; i < questions.length; i++) {
      final a = answers[i];
      if (a == null || a == 0) continue;
      answered++;
      if (a == questions[i].solution) {
        correct++;
      } else {
        incorrect++;
      }
    }
    var net = correct.toDouble();
    switch (errorFormat) {
      case 25:
        net -= incorrect / 4;
        break;
      case 33:
        net -= incorrect / 3;
        break;
      case 50:
        net -= incorrect / 2;
        break;
      case 100:
        net -= incorrect;
        break;
    }
    if (net < 0) net = 0;
    final total = questions.length;
    final percent = total == 0 ? 0.0 : (net / total) * 100;
    return Result(
      correct: correct,
      incorrect: incorrect,
      unanswered: total - answered,
      netScore: double.parse(net.toStringAsFixed(1)),
      percentScore: double.parse(percent.toStringAsFixed(1)),
    );
  }
}

class Result {
  final int correct;
  final int incorrect;
  final int unanswered;
  final double netScore;
  final double percentScore;

  Result({
    required this.correct,
    required this.incorrect,
    required this.unanswered,
    required this.netScore,
    required this.percentScore,
  });
}
