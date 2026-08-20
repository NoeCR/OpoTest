import '../domain/custom_test_draft.dart';

abstract class CustomTestRepository {
  Future<List<CustomTestSummary>> listSummaries({String? lawId});

  Future<CustomTestDraft?> getDraft(String testId);

  Future<String> save(CustomTestDraft draft);

  Future<void> delete(String testId);
}

/// Prefijo de IDs para evitar colisiones con el temario oficial.
const customTestIdPrefix = 'custom_';

String generateCustomTestId() => '$customTestIdPrefix${DateTime.now().microsecondsSinceEpoch}';

bool isCustomTestId(String id) => id.startsWith(customTestIdPrefix);
