/// Valor del desplegable para crear una sección nueva.
const customLawOthersOption = '__custom_law_new__';

const customLawIdPrefix = 'custom_law_';

bool isCustomLawId(String id) => id.startsWith(customLawIdPrefix);

bool isCustomLawOthersOption(String? id) => id == customLawOthersOption;

String generateCustomLawId() => '$customLawIdPrefix${DateTime.now().microsecondsSinceEpoch}';

bool needsCustomLawName(CustomTestDraftLike draft) {
  return isCustomLawOthersOption(draft.lawId) || isCustomLawId(draft.lawId);
}

/// Evita dependencia circular en validación.
abstract class CustomTestDraftLike {
  String get lawId;
  String get lawName;
  String get customLawName;
}
