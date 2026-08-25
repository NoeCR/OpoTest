import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Credenciales OAuth de tipo "aplicación de escritorio" + cliente web (Android).
///
/// Prioridad: `--dart-define` → `google_oauth.json` junto a la app o en `app/`.
class GoogleOAuthConfig {
  const GoogleOAuthConfig({
    this.desktopClientId = '',
    this.desktopClientSecret = '',
    this.serverClientId = '',
  });

  final String desktopClientId;
  final String desktopClientSecret;
  final String serverClientId;

  bool get hasDesktopClient =>
      desktopClientId.trim().isNotEmpty && desktopClientSecret.trim().isNotEmpty;

  bool get hasServerClient => serverClientId.trim().isNotEmpty;

  bool get isConfigured {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return hasDesktopClient;
    }
    return hasServerClient || hasDesktopClient;
  }

  static GoogleOAuthConfig fromEnvironment() {
    return GoogleOAuthConfig(
      desktopClientId: const String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID'),
      desktopClientSecret: const String.fromEnvironment('GOOGLE_OAUTH_CLIENT_SECRET'),
      serverClientId: const String.fromEnvironment('GOOGLE_OAUTH_SERVER_CLIENT_ID'),
    );
  }

  static Future<GoogleOAuthConfig> load() async {
    final env = fromEnvironment();
    if (env.isConfigured) return env;

    for (final file in _candidateFiles()) {
      if (!file.existsSync()) continue;
      try {
        final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final loaded = GoogleOAuthConfig(
          desktopClientId: data['desktop_client_id']?.toString() ?? env.desktopClientId,
          desktopClientSecret: data['desktop_client_secret']?.toString() ?? env.desktopClientSecret,
          serverClientId: data['server_client_id']?.toString() ?? env.serverClientId,
        );
        if (loaded.desktopClientId.isNotEmpty || loaded.serverClientId.isNotEmpty) {
          return loaded;
        }
      } catch (e) {
        debugPrint('GoogleOAuthConfig: no se pudo leer ${file.path}: $e');
      }
    }
    return env;
  }

  static List<File> _candidateFiles() {
    final paths = <String>{
      'google_oauth.json',
      p.join('app', 'google_oauth.json'),
    };
    try {
      final cwd = Directory.current.path;
      paths.add(p.join(cwd, 'google_oauth.json'));
      paths.add(p.join(cwd, 'app', 'google_oauth.json'));
      final parent = Directory.current.parent.path;
      paths.add(p.join(parent, 'google_oauth.json'));
      paths.add(p.join(parent, 'app', 'google_oauth.json'));
    } catch (_) {}
    try {
      paths.add(p.join(p.dirname(Platform.resolvedExecutable), 'google_oauth.json'));
    } catch (_) {}
    return [for (final path in paths) File(path)];
  }
}
