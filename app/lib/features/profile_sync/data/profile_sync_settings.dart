import 'package:shared_preferences/shared_preferences.dart';

class ProfileSyncSettings {
  static const _keyMongoUri = 'profile_sync_mongo_uri';
  static const _keyLegacyUrl = 'profile_sync_base_url';

  /// URI incrustada al compilar (`--dart-define-from-file=mongo_atlas.env.json`).
  static const compiledUri = String.fromEnvironment('MONGO_ATLAS_URI');

  static bool get hasCompiledUri => compiledUri.trim().isNotEmpty;

  Future<String> mongoUriOverride() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_keyMongoUri) ?? '').trim();
  }

  Future<String> mongoUri() async {
    final prefs = await SharedPreferences.getInstance();
    final override = (prefs.getString(_keyMongoUri) ?? '').trim();
    if (override.isNotEmpty) return override;
    final legacy = (prefs.getString(_keyLegacyUrl) ?? '').trim();
    if (legacy.startsWith('mongodb')) return legacy;
    return compiledUri.trim();
  }

  Future<void> setMongoUri(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_keyMongoUri);
    } else {
      await prefs.setString(_keyMongoUri, trimmed);
    }
  }
}
