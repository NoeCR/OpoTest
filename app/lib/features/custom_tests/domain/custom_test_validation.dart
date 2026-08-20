import 'custom_law.dart';
import 'custom_test_draft.dart';

class CustomTestValidationException implements Exception {
  CustomTestValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

void validateCustomTestDraft(CustomTestDraft draft) {
  if (isCustomLawOthersOption(draft.lawId)) {
    if (draft.effectiveCustomLawName.isEmpty) {
      throw CustomTestValidationException('Indica el nombre de la sección.');
    }
  } else if (draft.lawId.trim().isEmpty) {
    throw CustomTestValidationException('Selecciona una ley o sección.');
  } else if (isCustomLawId(draft.lawId) && draft.effectiveCustomLawName.isEmpty) {
    throw CustomTestValidationException('Indica el nombre de la sección.');
  }
  if (draft.name.trim().isEmpty) {
    throw CustomTestValidationException('Indica un nombre para el test.');
  }
  if (draft.questions.isEmpty) {
    throw CustomTestValidationException('Añade al menos una pregunta.');
  }
  if (draft.questions.length > 100) {
    throw CustomTestValidationException('El test no puede tener más de 100 preguntas.');
  }

  for (var i = 0; i < draft.questions.length; i++) {
    final q = draft.questions[i];
    final n = i + 1;
    if (q.text.trim().isEmpty) {
      throw CustomTestValidationException('La pregunta $n necesita enunciado.');
    }
    for (var a = 0; a < 4; a++) {
      if (q.answers[a].trim().isEmpty) {
        throw CustomTestValidationException('La pregunta $n necesita la respuesta ${a + 1}.');
      }
    }
    if (q.solution < 1 || q.solution > 4) {
      throw CustomTestValidationException('Marca la respuesta correcta en la pregunta $n.');
    }
  }
}
