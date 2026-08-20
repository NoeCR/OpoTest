import '../models/question.dart';

class ReviewEntry {
  const ReviewEntry({
    required this.testId,
    required this.testName,
    required this.questionIndex,
    required this.question,
    required this.markedAt,
  });

  final String testId;
  final String testName;
  final int questionIndex;
  final Question question;
  final DateTime markedAt;
}
