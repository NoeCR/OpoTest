/// Identidad pública de la aplicación (exports, validación, logs).
abstract final class AppConstants {
  static const name = 'OpoTest';
  static const id = 'opotest';
  static const androidApplicationId = 'com.opotest.app';

  /// IDs aceptados al importar backups anteriores al rebrand.
  static const legacyIds = {'testea_local'};
}

bool isKnownAppId(String? value) {
  if (value == null || value.isEmpty) return false;
  return value == AppConstants.id || AppConstants.legacyIds.contains(value);
}
