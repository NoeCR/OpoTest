class LocalUser {
  final String id;
  final String name;
  final DateTime createdAt;

  const LocalUser({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt.toIso8601String(),
      };

  factory LocalUser.fromMap(Map<String, dynamic> map) => LocalUser(
        id: map['id'] as String,
        name: map['name'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class TestAttempt {
  final String id;
  final String userId;
  final String testId;
  final String testName;
  final DateTime finishedAt;
  final int durationSeconds;
  final double netScore;
  final double percentScore;
  final Map<int, int> answers;
  final bool examSimulation;
  final int errorFormat;

  const TestAttempt({
    required this.id,
    required this.userId,
    required this.testId,
    required this.testName,
    required this.finishedAt,
    required this.durationSeconds,
    required this.netScore,
    required this.percentScore,
    required this.answers,
    required this.examSimulation,
    required this.errorFormat,
  });
}
