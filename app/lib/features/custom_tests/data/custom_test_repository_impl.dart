import '../../../database/app_database.dart';
import '../../../models/question.dart';
import '../domain/custom_law.dart';
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
    final draft = _payloadBuilder.draftFromPayload(payload, lawCode: lawCode);
    if (isCustomLawId(draft.lawId)) {
      return draft.copyWith(customLawName: draft.lawName);
    }
    return draft;
  }

  @override
  Future<String> save(CustomTestDraft draft) async {
    final resolved = await _resolveLaw(draft);
    final testId = resolved.isEditing ? resolved.id! : generateCustomTestId();
    final payload = _payloadBuilder.build(testId: testId, draft: resolved);
    await _db.upsertCustomTest(payload);
    return testId;
  }

  Future<CustomTestDraft> _resolveLaw(CustomTestDraft draft) async {
    if (isCustomLawOthersOption(draft.lawId)) {
      final lawId = generateCustomLawId();
      final name = draft.effectiveCustomLawName;
      await _db.upsertCustomLaw(id: lawId, name: name);
      return draft.copyWith(
        lawId: lawId,
        lawCode: name,
        lawName: name,
        customLawName: name,
      );
    }

    if (isCustomLawId(draft.lawId)) {
      final name = draft.effectiveCustomLawName;
      await _db.upsertCustomLaw(id: draft.lawId, name: name);
      return draft.copyWith(lawCode: name, lawName: name, customLawName: name);
    }

    return draft;
  }

  @override
  Future<void> delete(String testId) async {
    await _db.deleteCustomTest(testId);
  }
}
