import 'package:flutter_test/flutter_test.dart';
import 'package:testea_local/features/custom_tests/domain/custom_law.dart';
import 'package:testea_local/features/custom_tests/domain/custom_question_draft.dart';
import 'package:testea_local/features/custom_tests/domain/custom_test_draft.dart';
import 'package:testea_local/features/custom_tests/domain/custom_test_validation.dart';

void main() {
  group('validateCustomTestDraft', () {
    CustomTestDraft validDraft() {
      return CustomTestDraft(
        lawId: '1',
        name: 'Mi test',
        questions: [
          CustomQuestionDraft(
            text: '¿Pregunta?',
            answers: ['A', 'B', 'C', 'D'],
            solution: 2,
          ),
        ],
      );
    }

    test('acepta un borrador válido', () {
      expect(() => validateCustomTestDraft(validDraft()), returnsNormally);
    });

    test('exige ley', () {
      expect(
        () => validateCustomTestDraft(validDraft().copyWith(lawId: '')),
        throwsA(isA<CustomTestValidationException>()),
      );
    });

    test('exige nombre', () {
      expect(
        () => validateCustomTestDraft(validDraft().copyWith(name: '  ')),
        throwsA(isA<CustomTestValidationException>()),
      );
    });

    test('exige las cuatro respuestas', () {
      final q = CustomQuestionDraft(text: 'P', answers: ['A', '', 'C', 'D'], solution: 1);
      expect(
        () => validateCustomTestDraft(validDraft().copyWith(questions: [q])),
        throwsA(isA<CustomTestValidationException>()),
      );
    });
    test('exige nombre de sección cuando se elige Otros', () {
      expect(
        () => validateCustomTestDraft(
          validDraft().copyWith(lawId: customLawOthersOption, customLawName: '  '),
        ),
        throwsA(isA<CustomTestValidationException>()),
      );
    });
  });
}
