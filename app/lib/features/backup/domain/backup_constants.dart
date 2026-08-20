const contentBackupKind = 'content_backup';
const progressBackupKind = 'progress_backup';

const contentBackupVersion = 1;
const progressBackupVersion = 2;

/// Compatibilidad con export de progreso v1 (perfil).
const progressBackupLegacyVersion = 1;

enum BackupKind { content, progress, unknown }

BackupKind backupKindFromPayload(Map<String, dynamic> payload) {
  final kind = payload['kind']?.toString();
  if (kind == contentBackupKind) return BackupKind.content;
  if (kind == progressBackupKind) return BackupKind.progress;
  if (payload['attempts'] is List && payload['user'] is Map) return BackupKind.progress;
  if (payload['laws'] is List || payload['tests'] is List) return BackupKind.content;
  return BackupKind.unknown;
}
