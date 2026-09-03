import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

import '../domain/profile_sync_repository.dart';

/// Cifra el JSON de progreso con el token del código. Un cambio de almacén no cambia esto.
class ProfileSyncCipher {
  const ProfileSyncCipher();

  String seal({
    required String syncId,
    required String token,
    required Map<String, dynamic> payload,
  }) {
    final iv = IV.fromSecureRandom(16);
    final encrypted = _encrypter(syncId, token).encrypt(jsonEncode(payload), iv: iv);
    return '${iv.base64}.${encrypted.base64}';
  }

  Map<String, dynamic> open({
    required String syncId,
    required String token,
    required String blob,
  }) {
    final parts = blob.split('.');
    if (parts.length != 2) {
      throw ProfileSyncException('Este código no coincide con el perfil remoto.');
    }
    try {
      final iv = IV.fromBase64(parts[0]);
      final plain = _encrypter(syncId, token).decrypt64(parts[1], iv: iv);
      final decoded = jsonDecode(plain);
      if (decoded is! Map<String, dynamic>) {
        throw ProfileSyncException('Este código no coincide con el perfil remoto.');
      }
      return decoded;
    } catch (e) {
      if (e is ProfileSyncException) rethrow;
      throw ProfileSyncException('Este código no coincide con el perfil remoto.');
    }
  }

  Encrypter _encrypter(String syncId, String token) {
    final bytes = sha256.convert(utf8.encode('$syncId|$token')).bytes;
    return Encrypter(AES(Key(Uint8List.fromList(bytes))));
  }
}
