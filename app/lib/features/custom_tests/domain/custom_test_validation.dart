import 'custom_test_draft.dart';

class CustomTestValidationException implements Exception {
  CustomTestValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

void validateCustomTestDraft(CustomTestDraft draft) {
  if (draft.lawId.trim().isEmpty) {
    throw CustomTestValidationException('Selecciona una ley.');
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
