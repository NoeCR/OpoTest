class QuestionReviewState {
  const QuestionReviewState({
    required this.userId,
    required this.testId,
    required this.questionIndex,
    required this.box,
    required this.nextDue,
    required this.lastResultCorrect,
  });

  final String userId;
  final String testId;
  final int questionIndex;
  final int box;
  final DateTime nextDue;
  final bool lastResultCorrect;

  static String keyOf(String testId, int questionIndex) => '$testId:$questionIndex';

  String get key => keyOf(testId, questionIndex);

  factory QuestionReviewState.fromMap(Map<String, dynamic> row) {
    return QuestionReviewState(
      userId: row['user_id']?.toString() ?? '',
      testId: row['test_id']?.toString() ?? '',
      questionIndex: (row['question_index'] as num?)?.toInt() ?? 0,
      box: (row['box'] as num?)?.toInt() ?? 1,
      nextDue: DateTime.tryParse(row['next_due']?.toString() ?? '') ?? DateTime(1970),
      lastResultCorrect: (row['last_result'] as num?)?.toInt() == 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'test_id': testId,
        'question_index': questionIndex,
        'box': box,
        'next_due': DateTime(nextDue.year, nextDue.month, nextDue.day).toIso8601String(),
        'last_result': lastResultCorrect ? 1 : 0,
      };
}
