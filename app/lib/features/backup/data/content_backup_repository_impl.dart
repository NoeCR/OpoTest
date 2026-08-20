import '../../../database/app_database.dart';
import '../../../app_constants.dart';
import '../domain/backup_constants.dart';
import '../domain/backup_repository.dart';

class ContentBackupRepositoryImpl implements ContentBackupRepository {
  ContentBackupRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Map<String, dynamic>> buildExportPayload() async {
    final snapshot = await _db.exportContentSnapshot();
    return {
      'app': AppConstants.id,
      'kind': contentBackupKind,
      'version': contentBackupVersion,
      'exported_at': DateTime.now().toIso8601String(),
      ...snapshot,
    };
  }

  @override
  Future<ContentImportResult> importPayload(Map<String, dynamic> payload) async {
    final stats = await _db.importContentSnapshot(payload);
    return ContentImportResult(
      laws: stats['laws'] ?? 0,
      titles: stats['titles'] ?? 0,
      testsOfficial: stats['tests_official'] ?? 0,
      testsCustom: stats['tests_custom'] ?? 0,
      testsSkipped: stats['tests_skipped'] ?? 0,
    );
  }
}
