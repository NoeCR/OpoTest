class MarkedQuestion {
  const MarkedQuestion({
    required this.userId,
    required this.testId,
    required this.questionIndex,
    required this.markedAt,
  });

  final String userId;
  final String testId;
  final int questionIndex;
  final DateTime markedAt;

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'test_id': testId,
        'question_index': questionIndex,
        'marked_at': markedAt.toIso8601String(),
      };

  factory MarkedQuestion.fromMap(Map<String, dynamic> map) => MarkedQuestion(
        userId: map['user_id'] as String,
        testId: map['test_id'] as String,
        questionIndex: (map['question_index'] as num).toInt(),
        markedAt: DateTime.parse(map['marked_at'] as String),
      );
}
