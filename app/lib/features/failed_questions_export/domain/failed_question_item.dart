import '../../../models/question.dart';

class FailedQuestionItem {
  const FailedQuestionItem({
    required this.testId,
    required this.testName,
    required this.questionIndex,
    required this.question,
    required this.userAnswer,
    required this.failedAt,
    required this.lawCode,
    required this.lawName,
    this.titleName,
  });

  final String testId;
  final String testName;
  final int questionIndex;
  final Question question;
  final int userAnswer;
  final DateTime failedAt;
  final String lawCode;
  final String lawName;
  final String? titleName;

  int get correctAnswer => question.solution;

  String get lawLabel {
    if (lawCode.isNotEmpty && lawName.isNotEmpty && lawCode != lawName) {
      return '$lawCode · $lawName';
    }
    return lawName.isNotEmpty ? lawName : (lawCode.isNotEmpty ? lawCode : 'Ley no indicada');
  }
}

class FailedQuestionsCollectResult {
  const FailedQuestionsCollectResult({
    required this.items,
    required this.skippedMissingTests,
  });

  final List<FailedQuestionItem> items;
  final int skippedMissingTests;
}
