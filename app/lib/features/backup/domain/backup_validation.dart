import '../../../app_constants.dart';
import 'backup_constants.dart';

class BackupValidationException implements Exception {
  BackupValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

void validateContentBackup(Map<String, dynamic> payload) {
  if (!isKnownAppId(payload['app']?.toString())) {
    throw BackupValidationException('Archivo no válido para ${AppConstants.name}.');
  }
  if (payload['kind'] != contentBackupKind) {
    throw BackupValidationException('No es una copia de contenido.');
  }
  final version = (payload['version'] as num?)?.toInt();
  if (version == null || version > contentBackupVersion) {
    throw BackupValidationException('Versión de backup no compatible.');
  }
  if (payload['tests'] is! List) {
    throw BackupValidationException('Formato de tests inválido.');
  }
}

void validateProgressBackup(Map<String, dynamic> payload) {
  if (!isKnownAppId(payload['app']?.toString())) {
    throw BackupValidationException('Archivo no válido para ${AppConstants.name}.');
  }
  final kind = payload['kind']?.toString();
  final version = (payload['version'] as num?)?.toInt() ?? progressBackupLegacyVersion;
  if (version > progressBackupVersion) {
    throw BackupValidationException('Versión de backup no compatible.');
  }
  if (kind == progressBackupKind || kind == null) {
    final hasUsers = payload['users'] is List || payload['user'] is Map;
    if (!hasUsers) {
      throw BackupValidationException('No contiene perfiles.');
    }
    if (payload['attempts'] is! List) {
      throw BackupValidationException('Formato de intentos inválido.');
    }
    return;
  }
  throw BackupValidationException('No es una copia de progreso.');
}

Map<String, dynamic> normalizeProgressBackup(Map<String, dynamic> payload) {
  final normalized = Map<String, dynamic>.from(payload);
  if (normalized['kind'] == null) {
    normalized['kind'] = progressBackupKind;
  }
  if (normalized['users'] == null && normalized['user'] is Map) {
    normalized['users'] = [normalized['user']];
  }
  final attempts = (normalized['attempts'] as List? ?? []).map((raw) {
    final row = Map<String, dynamic>.from(raw as Map);
    if (row['user_id'] == null && normalized['users'] is List) {
      final users = normalized['users'] as List;
      if (users.length == 1) {
        row['user_id'] = (users.first as Map)['id'];
      }
    }
    if (row['answers'] is Map) {
      row['answers_json'] = row['answers'];
    }
    return row;
  }).toList();
  normalized['attempts'] = attempts;
  return normalized;
}
