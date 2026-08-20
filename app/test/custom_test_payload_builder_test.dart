import 'package:flutter_test/flutter_test.dart';
import 'package:testea_local/features/custom_tests/data/custom_test_payload_builder.dart';
import 'package:testea_local/features/custom_tests/domain/custom_question_draft.dart';
import 'package:testea_local/features/custom_tests/domain/custom_test_draft.dart';
import 'package:testea_local/models/content_kind.dart';
import 'package:testea_local/models/question.dart';

void main() {
  const builder = CustomTestPayloadBuilder();

  test('build genera payload compatible con TestDefinition', () {
    const draft = CustomTestDraft(
      lawId: '10',
      lawCode: 'CE',
      lawName: 'Constitución',
      name: 'Repaso art. 1',
      questions: [
        CustomQuestionDraft(
          text: '¿Qué es España?',
          answers: ['Una monarquía', 'Un estado social', 'Una república', 'Una confederación'],
          solution: 2,
          clarificationHtml: 'Art. 1 CE',
        ),
      ],
    );

    final payload = builder.build(testId: 'custom_123', draft: draft);
    final def = TestDefinition.fromApiJson(payload);
    final test = payload['test'] as Map<String, dynamic>;

    expect(def.id, 'custom_123');
    expect(def.name, 'Repaso art. 1');
    expect(def.type, ContentKind.own.dbType);
    expect(def.questions, hasLength(1));
    expect(def.questions.first.solution, 2);
    expect(test['idLaw'], '10');
    expect(test['law_code'], 'CE');
  });

  test('draftFromPayload reconstruye el borrador', () {
    const draft = CustomTestDraft(
      lawId: '10',
      lawCode: 'CE',
      lawName: 'Constitución',
      name: 'Test roundtrip',
      questions: [
        CustomQuestionDraft(
          text: 'P1',
          answers: ['a', 'b', 'c', 'd'],
          solution: 3,
          clarificationHtml: 'nota',
        ),
      ],
    );

    final payload = builder.build(testId: 'custom_999', draft: draft);
    final restored = builder.draftFromPayload(payload, lawCode: 'CE');

    expect(restored.id, 'custom_999');
    expect(restored.lawId, '10');
    expect(restored.name, 'Test roundtrip');
    expect(restored.questions.first.text, 'P1');
    expect(restored.questions.first.solution, 3);
    expect(restored.questions.first.clarificationHtml, 'nota');
  });
}
