import 'dart:io';

import '../data/backup_file_io.dart';
import '../domain/backup_repository.dart';
import '../domain/backup_validation.dart';

class ContentBackupService {
  ContentBackupService(this._repository, {BackupFileIo? fileIo})
      : _fileIo = fileIo ?? BackupFileIo();

  final ContentBackupRepository _repository;
  final BackupFileIo _fileIo;

  Future<BackupFileResult> export({Directory? targetDir}) async {
    final payload = await _repository.buildExportPayload();
    final written = await _fileIo.writePayload(
      prefix: 'opotest_content',
      payload: payload,
      targetDir: targetDir,
    );
    final stats = Map<String, dynamic>.from(payload['stats'] as Map? ?? {});
    return BackupFileResult(filePath: written.filePath, stats: stats);
  }

  Future<ContentImportResult> importFromPicker() async {
    final payload = await _fileIo.pickAndReadJson();
    validateContentBackup(payload);
    return _repository.importPayload(payload);
  }
}
