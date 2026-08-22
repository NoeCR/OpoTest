import '../models/question.dart';

class TestScoring {
  static const maxGrade = 10.0;

  /// Nota sobre 10 a partir de valores guardados (compatible con intentos antiguos).
  static double gradeOnTen({required double netScore, required double percentScore}) {
    if (netScore >= 0 && netScore <= maxGrade) return netScore;
    return (percentScore / 10).clamp(0, maxGrade);
  }

  static String formatGrade(double grade) {
    final rounded = double.parse(grade.toStringAsFixed(1));
    return rounded == rounded.roundToDouble()
        ? rounded.round().toString()
        : rounded.toStringAsFixed(1);
  }

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
    var rawNet = correct.toDouble();
    switch (errorFormat) {
      case 25:
        rawNet -= incorrect / 4;
        break;
      case 33:
        rawNet -= incorrect / 3;
        break;
      case 50:
        rawNet -= incorrect / 2;
        break;
      case 100:
        rawNet -= incorrect;
        break;
    }
    if (rawNet < 0) rawNet = 0;
    final total = questions.length;
    final ratio = total == 0 ? 0.0 : (rawNet / total).clamp(0.0, 1.0);
    final netScore = double.parse((ratio * maxGrade).toStringAsFixed(1));
    final percentScore = double.parse((ratio * 100).toStringAsFixed(1));
    return Result(
      correct: correct,
      incorrect: incorrect,
      unanswered: total - answered,
      netScore: netScore,
      percentScore: percentScore,
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
