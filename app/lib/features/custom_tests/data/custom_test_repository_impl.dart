import '../../../database/app_database.dart';
import '../../../models/question.dart';
import '../domain/custom_test_draft.dart';
import '../domain/custom_test_repository.dart';
import 'custom_test_payload_builder.dart';

class CustomTestRepositoryImpl implements CustomTestRepository {
  CustomTestRepositoryImpl(this._db, {CustomTestPayloadBuilder? payloadBuilder})
      : _payloadBuilder = payloadBuilder ?? const CustomTestPayloadBuilder();

  final AppDatabase _db;
  final CustomTestPayloadBuilder _payloadBuilder;

  @override
  Future<List<CustomTestSummary>> listSummaries({String? lawId}) async {
    final rows = await _db.listCustomTestRows(lawId: lawId);
    final laws = {for (final l in await _db.getLaws()) l['id'] as String: l['code'] as String? ?? ''};

    return rows.map((row) {
      final payload = row['payload'] as Map<String, dynamic>;
      final def = TestDefinition.fromApiJson(payload);
      final id = row['id'] as String;
      final lid = row['law_id'] as String;
      return CustomTestSummary(
        id: id,
        lawId: lid,
        lawCode: laws[lid] ?? '',
        name: def.name,
        questionCount: def.questions.length,
      );
    }).toList();
  }

  @override
  Future<CustomTestDraft?> getDraft(String testId) async {
    final row = await _db.getCustomTestRow(testId);
    if (row == null) return null;
    final payload = row['payload'] as Map<String, dynamic>;
    final lawCode = row['law_code'] as String? ?? '';
    return _payloadBuilder.draftFromPayload(payload, lawCode: lawCode);
  }

  @override
  Future<String> save(CustomTestDraft draft) async {
    final testId = draft.isEditing ? draft.id! : generateCustomTestId();
    final payload = _payloadBuilder.build(testId: testId, draft: draft);
    await _db.upsertCustomTest(payload);
    return testId;
  }

  @override
  Future<void> delete(String testId) async {
    await _db.deleteCustomTest(testId);
  }
}
