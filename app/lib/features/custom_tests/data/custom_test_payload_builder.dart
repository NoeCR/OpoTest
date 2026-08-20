import '../../../models/content_kind.dart';
import '../../../models/question.dart';
import '../domain/custom_question_draft.dart';
import '../domain/custom_test_draft.dart';

/// Genera JSON compatible con [TestDefinition.fromApiJson] para tests propios.
class CustomTestPayloadBuilder {
  const CustomTestPayloadBuilder();

  Map<String, dynamic> build({
    required String testId,
    required CustomTestDraft draft,
  }) {
    final questions = <Map<String, dynamic>>[];
    for (var i = 0; i < draft.questions.length; i++) {
      final q = draft.questions[i];
      questions.add({
        'order': '${i + 1}',
        'q': {
          'text_es': q.text.trim(),
          'answer1_es': q.answers[0].trim(),
          'answer2_es': q.answers[1].trim(),
          'answer3_es': q.answers[2].trim(),
          'answer4_es': q.answers[3].trim(),
          'solution': '${q.solution}',
          'textClarification_es': q.clarificationHtml.trim(),
        },
      });
    }

    return {
      'error': 0,
      'test': {
        'id': testId,
        'idLaw': draft.lawId,
        'idTitle': '',
        'idChapter': '',
        'idSection': '',
        'idArticle': '',
        'name': draft.name.trim(),
        'type': ContentKind.own.dbType,
        'law_code': draft.lawCode,
        'law_name': draft.lawName,
        'index': '0',
        'q': {
          '1': questions,
        },
      },
    };
  }

  CustomTestDraft draftFromPayload(
    Map<String, dynamic> payload, {
    required String lawCode,
  }) {
    final def = TestDefinition.fromApiJson(payload);
    final test = payload['test'] as Map<String, dynamic>? ?? {};

    final questionDrafts = def.questions
        .map(
          (q) => CustomQuestionDraft(
            text: q.text,
            answers: List<String>.from(q.answers),
            solution: q.solution,
            clarificationHtml: q.clarificationHtml,
          ),
        )
        .toList();

    return CustomTestDraft(
      id: def.id,
      lawId: test['idLaw']?.toString() ?? '',
      lawCode: lawCode.isNotEmpty ? lawCode : test['law_code']?.toString() ?? '',
      lawName: test['law_name']?.toString() ?? '',
      name: def.name,
      questions: questionDrafts.isEmpty ? [CustomQuestionDraft.empty()] : questionDrafts,
    );
  }
}
