import 'custom_question_draft.dart';

class CustomTestDraft {
  const CustomTestDraft({
    this.id,
    required this.lawId,
    this.lawCode = '',
    this.lawName = '',
    this.name = '',
    this.questions = const [],
  });

  final String? id;
  final String lawId;
  final String lawCode;
  final String lawName;
  final String name;
  final List<CustomQuestionDraft> questions;

  bool get isEditing => id != null && id!.isNotEmpty;

  CustomTestDraft copyWith({
    String? id,
    String? lawId,
    String? lawCode,
    String? lawName,
    String? name,
    List<CustomQuestionDraft>? questions,
  }) {
    return CustomTestDraft(
      id: id ?? this.id,
      lawId: lawId ?? this.lawId,
      lawCode: lawCode ?? this.lawCode,
      lawName: lawName ?? this.lawName,
      name: name ?? this.name,
      questions: questions ?? List<CustomQuestionDraft>.from(this.questions),
    );
  }

  static CustomTestDraft empty({String lawId = ''}) {
    return CustomTestDraft(
      lawId: lawId,
      questions: [CustomQuestionDraft.empty()],
    );
  }
}

class CustomTestSummary {
  const CustomTestSummary({
    required this.id,
    required this.lawId,
    required this.lawCode,
    required this.name,
    required this.questionCount,
  });

  final String id;
  final String lawId;
  final String lawCode;
  final String name;
  final int questionCount;
}
