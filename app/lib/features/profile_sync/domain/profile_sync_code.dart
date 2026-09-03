class ProfileSyncCode {
  static const prefix = 'ot1';

  const ProfileSyncCode({required this.syncId, required this.token});

  final String syncId;
  final String token;

  String get compact => '$prefix.$syncId.$token';

  static String normalizeId(String raw) =>
      raw.trim().toLowerCase().replaceAll('-', '').replaceAll(' ', '');

  static ProfileSyncCode parse(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'\s+'), '');
    final parts = cleaned.split('.');
    if (parts.length != 3 || parts[0].toLowerCase() != prefix) {
      throw const FormatException(
        'Código no válido. Debe ser el que copiaste al activar la sincronización.',
      );
    }
    final syncId = normalizeId(parts[1]);
    final token = normalizeId(parts[2]);
    if (!_isHex32(syncId) || !_isHex32(token)) {
      throw const FormatException('Código incompleto o alterado.');
    }
    return ProfileSyncCode(syncId: syncId, token: token);
  }

  static bool _isHex32(String value) =>
      RegExp(r'^[0-9a-f]{32}$').hasMatch(value);
}
