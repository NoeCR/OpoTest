import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';

import '../domain/profile_sync_link.dart';
import '../domain/profile_sync_repository.dart';
import 'profile_sync_cipher.dart';

const _defaultDb = 'opotest';
const _collection = 'profile_sync';

class MongoAtlasProfileSyncRepository implements ProfileSyncRepository {
  MongoAtlasProfileSyncRepository({
    required this.uri,
    ProfileSyncCipher cipher = const ProfileSyncCipher(),
  })  : _cipher = cipher,
        _normalizedUri = _withDatabase(uri);

  final String uri;
  final ProfileSyncCipher _cipher;
  final String _normalizedUri;
  Db? _db;

  static String _withDatabase(String raw) {
    final uri = raw.trim();
    final schemeEnd = uri.indexOf('://');
    if (schemeEnd < 0) return uri;
    final rest = uri.substring(schemeEnd + 3);
    final hostStart = rest.lastIndexOf('@') + 1;
    final hostAndAfter = rest.substring(hostStart);
    final slash = hostAndAfter.indexOf('/');
    if (slash < 0) {
      final q = hostAndAfter.indexOf('?');
      if (q < 0) return '$uri/$_defaultDb';
      final insertAt = schemeEnd + 3 + hostStart + q;
      return '${uri.substring(0, insertAt)}/$_defaultDb${uri.substring(insertAt)}';
    }
    final afterSlash = hostAndAfter.substring(slash);
    if (afterSlash == '/' || afterSlash.startsWith('/?')) {
      final insertAt = schemeEnd + 3 + hostStart + slash + 1;
      return '${uri.substring(0, insertAt)}$_defaultDb${uri.substring(insertAt)}';
    }
    return uri;
  }

  Future<DbCollection> _collectionRef() async {
    var db = _db;
    if (db == null || !db.isConnected) {
      try {
        db = await Db.create(_normalizedUri);
        // mongodb+srv ya implica TLS; no pasar secure: true otra vez.
        await db.open().timeout(const Duration(seconds: 25));
        _db = db;
      } catch (e) {
        debugPrint('Atlas connect: $e');
        throw ProfileSyncException(_describeConnectError(e));
      }
    }
    return db.collection(_collection);
  }

  static String _describeConnectError(Object e) {
    final text = e.toString().toLowerCase();
    if (text.contains('ip') ||
        text.contains('whitelist') ||
        text.contains('not authorized to access') ||
        text.contains('atlaserror') && text.contains('ip')) {
      return 'Atlas rechazó la IP. En Network Access pulsa Add IP Address → Allow Access from Anywhere (0.0.0.0/0).';
    }
    if (text.contains('auth') || text.contains('authentication') || text.contains('credential')) {
      return 'Usuario o contraseña incorrectos. En Database Access comprueba el usuario y que la URI no tenga < > ni la contraseña sin codificar.';
    }
    if (text.contains('srv') || text.contains('dns') || text.contains('seedlist')) {
      return 'No se resolvió el cluster (DNS SRV). Comprueba la URI mongodb+srv y la conexión a internet de la tablet.';
    }
    if (text.contains('timed out') || text.contains('timeout') || text.contains('tiempo')) {
      return 'Tiempo de espera agotado. Revisa Network Access (0.0.0.0/0) y que el cluster no esté pausado.';
    }
    return 'No se pudo conectar a Atlas. En el cluster: Network Access → 0.0.0.0/0, Database Access → usuario, y URI de Connect → Drivers.';
  }

  @override
  Future<ProfileSyncSnapshot?> getProfile({
    required String syncId,
    required String token,
  }) async {
    final col = await _collectionRef();
    final doc = await col.findOne(where.eq('_id', syncId));
    if (doc == null) return null;
    final blob = doc['blob']?.toString();
    if (blob == null || blob.isEmpty) {
      throw ProfileSyncException('El perfil remoto no contiene progreso.');
    }
    final payload = _cipher.open(syncId: syncId, token: token, blob: blob);
    return ProfileSyncSnapshot(
      updatedAt: DateTime.tryParse(doc['updated_at']?.toString() ?? '') ?? DateTime.now().toUtc(),
      payload: payload,
    );
  }

  @override
  Future<void> putProfile({
    required String syncId,
    required String token,
    required DateTime updatedAt,
    required Map<String, dynamic> payload,
  }) async {
    final col = await _collectionRef();
    final blob = _cipher.seal(syncId: syncId, token: token, payload: payload);
    await col.replaceOne(
      where.eq('_id', syncId),
      {
        '_id': syncId,
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'blob': blob,
      },
      upsert: true,
    );
  }
}
