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

  Future<BackupFileResult> exportAll({
    Directory? targetDir,
    String? profileName,
  }) async {
    final payload = await _repository.buildExportPayload();
    final at = DateTime.now();
    final name = (profileName != null && profileName.trim().isNotEmpty)
        ? profileName.trim()
        : 'todos-los-perfiles';
    final shareName = backupShareLabel(profileName: name, at: at);
    final written = await _fileIo.writePayload(
      fileName: backupExportFileName(profileName: name, at: at),
      payload: payload,
      targetDir: targetDir,
    );
    return BackupFileResult(
      filePath: written.filePath,
      shareName: shareName,
      stats: Map<String, dynamic>.from(payload['summary'] as Map? ?? {}),
    );
  }

  Future<BackupFileResult> exportUser({
    required LocalUser user,
    Directory? targetDir,
  }) async {
    final payload = await _repository.buildExportPayload(userId: user.id);
    final at = DateTime.now();
    final shareName = backupShareLabel(profileName: user.name, at: at);
    final written = await _fileIo.writePayload(
      fileName: backupExportFileName(profileName: user.name, at: at),
      payload: payload,
      targetDir: targetDir,
    );
    return BackupFileResult(
      filePath: written.filePath,
      shareName: shareName,
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
