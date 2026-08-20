import 'dart:io';

import '../../../models/local_user.dart';
import '../data/backup_file_io.dart';
import '../domain/backup_repository.dart';
import '../domain/backup_validation.dart';

class ProgressBackupService {
  ProgressBackupService(this._repository, {BackupFileIo? fileIo})
      : _fileIo = fileIo ?? BackupFileIo();

  final ProgressBackupRepository _repository;
  final BackupFileIo _fileIo;

  Future<BackupFileResult> exportAll({Directory? targetDir}) async {
    final payload = await _repository.buildExportPayload();
    final written = await _fileIo.writePayload(
      prefix: 'opotest_progress',
      payload: payload,
      targetDir: targetDir,
    );
    return BackupFileResult(
      filePath: written.filePath,
      stats: Map<String, dynamic>.from(payload['summary'] as Map? ?? {}),
    );
  }

  Future<BackupFileResult> exportUser({
    required LocalUser user,
    Directory? targetDir,
  }) async {
    final payload = await _repository.buildExportPayload(userId: user.id);
    final safeName = user.name.replaceAll(RegExp(r'[^\w\-]+'), '_').toLowerCase();
    final written = await _fileIo.writePayload(
      prefix: 'opotest_progress_$safeName',
      payload: payload,
      targetDir: targetDir,
    );
    return BackupFileResult(
      filePath: written.filePath,
      stats: Map<String, dynamic>.from(payload['summary'] as Map? ?? {}),
    );
  }

  Future<ProgressImportResult> importFromPicker({bool replaceExistingUsers = false}) async {
    final raw = await _fileIo.pickAndReadJson();
    final payload = normalizeProgressBackup(raw);
    validateProgressBackup(payload);
    return _repository.importPayload(
      payload,
      replaceExistingUsers: replaceExistingUsers,
    );
  }
}
