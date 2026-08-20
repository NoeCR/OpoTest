import 'dart:convert';

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

  factory TestAttempt.fromMap(Map<String, dynamic> row) {
    Map<int, int> answers = {};
    final rawAnswers = row['answers'];
    if (rawAnswers is Map) {
      answers = rawAnswers.map(
        (k, v) => MapEntry(int.parse(k.toString()), (v as num).toInt()),
      );
    } else {
      try {
        final decoded = jsonDecode(row['answers_json'] as String? ?? '{}') as Map<String, dynamic>;
        answers = decoded.map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
      } catch (_) {}
    }

    return TestAttempt(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      testId: row['test_id'] as String,
      testName: row['test_name'] as String? ?? '',
      finishedAt: DateTime.parse(row['finished_at'] as String),
      durationSeconds: (row['duration_seconds'] as num?)?.toInt() ?? 0,
      netScore: (row['net_score'] as num?)?.toDouble() ?? 0,
      percentScore: (row['percent_score'] as num?)?.toDouble() ?? 0,
      answers: answers,
      examSimulation: row['exam_simulation'] == true || row['exam_simulation'] == 1,
      errorFormat: (row['error_format'] as num?)?.toInt() ?? 0,
    );
  }
}
