import '../domain/profile_sync_repository.dart';
import 'mongo_atlas_profile_sync_repository.dart';
import 'profile_sync_settings.dart';

/// Elige la implementación remota. Mañana: otro `if` y un repositorio nuevo.
class ProfileSyncRepositoryFactory {
  ProfileSyncRepositoryFactory(this._settings);

  final ProfileSyncSettings _settings;
  ProfileSyncRepository? _cached;
  String? _cachedUri;

  Future<ProfileSyncRepository?> open() async {
    final uri = await _settings.mongoUri();
    if (uri.isEmpty) return null;
    if (_cached != null && _cachedUri == uri) return _cached;

    if (uri.startsWith('mongodb://') || uri.startsWith('mongodb+srv://')) {
      _cached = MongoAtlasProfileSyncRepository(uri: uri);
      _cachedUri = uri;
      return _cached;
    }

    throw ProfileSyncException(
      'La URI debe ser de MongoDB Atlas (empieza por mongodb+srv://).',
    );
  }
}
