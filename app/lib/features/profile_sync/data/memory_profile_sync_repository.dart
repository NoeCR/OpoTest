import '../domain/profile_sync_link.dart';
import '../domain/profile_sync_repository.dart';

class MemoryProfileSyncRepository implements ProfileSyncRepository {
  final Map<String, _Record> _store = {};

  @override
  Future<ProfileSyncSnapshot?> getProfile({
    required String syncId,
    required String token,
  }) async {
    final record = _store[syncId];
    if (record == null) return null;
    if (record.token != token) {
      throw ProfileSyncException('Este código no coincide con el perfil remoto.');
    }
    return ProfileSyncSnapshot(updatedAt: record.updatedAt, payload: record.payload);
  }

  @override
  Future<void> putProfile({
    required String syncId,
    required String token,
    required DateTime updatedAt,
    required Map<String, dynamic> payload,
  }) async {
    final existing = _store[syncId];
    if (existing != null && existing.token != token) {
      throw ProfileSyncException('Este código no coincide con el perfil remoto.');
    }
    _store[syncId] = _Record(token: token, updatedAt: updatedAt, payload: Map<String, dynamic>.from(payload));
  }
}

class _Record {
  _Record({required this.token, required this.updatedAt, required this.payload});

  final String token;
  final DateTime updatedAt;
  final Map<String, dynamic> payload;
}
