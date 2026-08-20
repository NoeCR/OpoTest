import 'custom_law.dart';
import 'custom_question_draft.dart';

class CustomTestDraft implements CustomTestDraftLike {
  const CustomTestDraft({
    this.id,
    required this.lawId,
    this.lawCode = '',
    this.lawName = '',
    this.customLawName = '',
    this.name = '',
    this.questions = const [],
  });

  final String? id;
  @override
  final String lawId;
  final String lawCode;
  @override
  final String lawName;
  @override
  final String customLawName;
  final String name;
  final List<CustomQuestionDraft> questions;

  bool get isEditing => id != null && id!.isNotEmpty;

  bool get usesCustomLawSection =>
      isCustomLawOthersOption(lawId) || isCustomLawId(lawId);

  String get effectiveCustomLawName =>
      customLawName.trim().isNotEmpty ? customLawName.trim() : lawName.trim();

  CustomTestDraft copyWith({
    String? id,
    String? lawId,
    String? lawCode,
    String? lawName,
    String? customLawName,
    String? name,
    List<CustomQuestionDraft>? questions,
  }) {
    return CustomTestDraft(
      id: id ?? this.id,
      lawId: lawId ?? this.lawId,
      lawCode: lawCode ?? this.lawCode,
      lawName: lawName ?? this.lawName,
      customLawName: customLawName ?? this.customLawName,
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
