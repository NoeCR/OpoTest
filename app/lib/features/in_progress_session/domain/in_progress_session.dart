import 'dart:convert';

import '../../../models/question.dart';

String formatTestClock(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final m = safe ~/ 60;
  final s = safe % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

Map<int, int> decodeIntIntMap(String json) {
  if (json.isEmpty || json == '{}') return {};
  try {
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
  } catch (_) {
    return {};
  }
}

String encodeIntIntMap(Map<int, int> map) {
  return jsonEncode(map.map((k, v) => MapEntry(k.toString(), v)));
}

/// Sesión de test a medias. No es un intento: no entra en historial ni en fallos.
class InProgressSession {
  const InProgressSession({
    required this.userId,
    required this.testId,
    required this.testName,
    required this.payload,
    required this.answers,
    required this.currentIndex,
    required this.elapsedSeconds,
    required this.errorFormat,
    required this.durationMinutes,
    required this.examSimulation,
    required this.questionCount,
    required this.updatedAt,
  });

  final String userId;
  final String testId;
  final String testName;
  final Map<String, dynamic> payload;
  final Map<int, int> answers;
  final int currentIndex;
  final int elapsedSeconds;
  final int errorFormat;
  final int durationMinutes;
  final bool examSimulation;
  final int questionCount;
  final DateTime updatedAt;

  factory InProgressSession.fromLive({
    required String userId,
    required TestDefinition test,
    required Map<int, int> answers,
    required int currentIndex,
    required int elapsedSeconds,
    required int errorFormat,
    required int durationMinutes,
    required bool examSimulation,
    DateTime? updatedAt,
  }) {
    return InProgressSession(
      userId: userId,
      testId: test.id,
      testName: test.name,
      payload: test.toApiJson(),
      answers: Map<int, int>.from(answers),
      currentIndex: currentIndex,
      elapsedSeconds: elapsedSeconds,
      errorFormat: errorFormat,
      durationMinutes: durationMinutes,
      examSimulation: examSimulation,
      questionCount: test.questions.length,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  TestDefinition get test => TestDefinition.fromApiJson(payload);

  int get answeredCount => answers.values.where((v) => v > 0).length;

  String get progressLabel {
    final total = questionCount < 1 ? 1 : questionCount;
    final pos = (currentIndex + 1).clamp(1, total);
    return 'Pregunta $pos de $total · ${formatTestClock(elapsedSeconds)}';
  }

  InProgressSession copyWith({
    Map<int, int>? answers,
    int? currentIndex,
    int? elapsedSeconds,
    DateTime? updatedAt,
  }) {
    return InProgressSession(
      userId: userId,
      testId: testId,
      testName: testName,
      payload: payload,
      answers: answers ?? this.answers,
      currentIndex: currentIndex ?? this.currentIndex,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      errorFormat: errorFormat,
      durationMinutes: durationMinutes,
      examSimulation: examSimulation,
      questionCount: questionCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'test_id': testId,
        'test_name': testName,
        'payload': jsonEncode(payload),
        'answers_json': encodeIntIntMap(answers),
        'current_index': currentIndex,
        'elapsed_seconds': elapsedSeconds,
        'error_format': errorFormat,
        'duration_minutes': durationMinutes,
        'exam_simulation': examSimulation ? 1 : 0,
        'question_count': questionCount,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory InProgressSession.fromMap(Map<String, dynamic> row) {
    Map<String, dynamic> payload = {};
    try {
      final raw = row['payload'];
      if (raw is Map) {
        payload = Map<String, dynamic>.from(raw);
      } else {
        payload = jsonDecode(raw as String? ?? '{}') as Map<String, dynamic>;
      }
    } catch (_) {}

    return InProgressSession(
      userId: row['user_id'] as String? ?? '',
      testId: row['test_id'] as String? ?? '',
      testName: row['test_name'] as String? ?? '',
      payload: payload,
      answers: decodeIntIntMap(row['answers_json'] as String? ?? '{}'),
      currentIndex: (row['current_index'] as num?)?.toInt() ?? 0,
      elapsedSeconds: (row['elapsed_seconds'] as num?)?.toInt() ?? 0,
      errorFormat: (row['error_format'] as num?)?.toInt() ?? 0,
      durationMinutes: (row['duration_minutes'] as num?)?.toInt() ?? 0,
      examSimulation: row['exam_simulation'] == true || row['exam_simulation'] == 1,
      questionCount: (row['question_count'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
