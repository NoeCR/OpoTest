import 'profile_sync_link.dart';

/// Puerto de persistencia remota del progreso. El servicio no conoce Atlas ni HTTP.
abstract class ProfileSyncRepository {
  Future<ProfileSyncSnapshot?> getProfile({
    required String syncId,
    required String token,
  });

  Future<void> putProfile({
    required String syncId,
    required String token,
    required DateTime updatedAt,
    required Map<String, dynamic> payload,
  });
}

class ProfileSyncException implements Exception {
  ProfileSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}
