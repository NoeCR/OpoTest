import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../domain/progress_cloud_store.dart';
import '../domain/progress_sync_exception.dart';
import 'google_oauth_config.dart';

const _driveFileName = 'opotest_progress.json';
const _credentialsStorageKey = 'google_drive_credentials';
const _emailStorageKey = 'google_drive_email';
const _driveScope = 'https://www.googleapis.com/auth/drive.appdata';
const _emailScope = 'https://www.googleapis.com/auth/userinfo.email';

ProgressCloudStore createStore() => GoogleDriveProgressStore();

class GoogleDriveProgressStore implements ProgressCloudStore {
  GoogleDriveProgressStore({
    GoogleOAuthConfig? config,
    FlutterSecureStorage? storage,
    http.Client? httpClient,
  })  : _configOverride = config,
        _storage = storage ?? const FlutterSecureStorage(),
        _httpClient = httpClient ?? http.Client();

  final GoogleOAuthConfig? _configOverride;
  final FlutterSecureStorage _storage;
  final http.Client _httpClient;

  GoogleOAuthConfig _config = const GoogleOAuthConfig();
  AutoRefreshingAuthClient? _desktopClient;
  GoogleSignInAccount? _mobileAccount;
  String? _email;
  var _initialized = false;

  static const _scopes = [_driveScope, _emailScope];

  @override
  bool get isSignedIn => _desktopClient != null || _mobileAccount != null;

  @override
  String? get email => _email;

  Future<GoogleOAuthConfig> _ensureConfig() async {
    final override = _configOverride;
    if (override != null) return override;
    _config = await GoogleOAuthConfig.load();
    return _config;
  }

  @override
  Future<void> restoreSession() async {
    final config = await _ensureConfig();
    if (!config.isConfigured) return;

    if (_isDesktop) {
      await _restoreDesktopSession(config);
      return;
    }
    await _restoreMobileSession(config);
  }

  @override
  Future<void> signIn() async {
    final config = await _ensureConfig();
    if (!config.isConfigured) {
      throw ProgressSyncException(
        'Faltan las credenciales de Google. Crea un proyecto en Google Cloud y un archivo google_oauth.json '
        '(consulta docs/google-drive-sync.md).',
        notConfigured: true,
      );
    }
    if (_isDesktop) {
      await _signInDesktop(config);
      return;
    }
    await _signInMobile(config);
  }

  @override
  Future<void> signOut() async {
    try {
      if (_isDesktop) {
        _desktopClient?.close();
        _desktopClient = null;
      } else {
        await GoogleSignIn.instance.signOut();
        _mobileAccount = null;
      }
    } catch (e) {
      debugPrint('GoogleDriveProgressStore.signOut: $e');
    }
    _email = null;
    await _storage.delete(key: _credentialsStorageKey);
    await _storage.delete(key: _emailStorageKey);
  }

  @override
  Future<Map<String, dynamic>?> downloadProgress() async {
    final client = await _authClient();
    final api = drive.DriveApi(client);
    final fileId = await _findFileId(api);
    if (fileId == null) return null;

    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final bytes = await media.stream.fold<List<int>>(<int>[], (prev, chunk) => prev..addAll(chunk));
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.map((k, v) => MapEntry(k.toString(), v));
    throw ProgressSyncException('El archivo de Drive no contiene un JSON de progreso válido.');
  }

  @override
  Future<void> uploadProgress(Map<String, dynamic> payload) async {
    final client = await _authClient();
    final api = drive.DriveApi(client);
    final encoded = utf8.encode(jsonEncode(payload));
    final media = drive.Media(Stream<List<int>>.value(encoded), encoded.length, contentType: 'application/json');
    final fileId = await _findFileId(api);
    if (fileId == null) {
      await api.files.create(
        drive.File()
          ..name = _driveFileName
          ..parents = ['appDataFolder'],
        uploadMedia: media,
      );
      return;
    }
    await api.files.update(drive.File(), fileId, uploadMedia: media);
  }

  bool get _isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  Future<AuthClient> _authClient() async {
    if (_isDesktop) {
      if (_desktopClient == null) {
        await restoreSession();
      }
      final client = _desktopClient;
      if (client == null) {
        throw ProgressSyncException('Inicia sesión con Google para sincronizar el progreso.');
      }
      return client;
    }

    final account = _mobileAccount;
    if (account == null) {
      throw ProgressSyncException('Inicia sesión con Google para sincronizar el progreso.');
    }
    final authorization = await account.authorizationClient.authorizeScopes(_scopes);
    final credentials = AccessCredentials(
      AccessToken('Bearer', authorization.accessToken, DateTime.now().toUtc().add(const Duration(minutes: 50))),
      null,
      _scopes,
    );
    return authenticatedClient(_httpClient, credentials);
  }

  Future<String?> _findFileId(drive.DriveApi api) async {
    final listed = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_driveFileName' and trashed = false",
      $fields: 'files(id, name)',
    );
    final files = listed.files;
    if (files == null || files.isEmpty) return null;
    return files.first.id;
  }

  Future<void> _signInDesktop(GoogleOAuthConfig config) async {
    try {
      final client = await clientViaUserConsent(
        ClientId(config.desktopClientId, config.desktopClientSecret),
        _scopes,
        (url) async {
          final uri = Uri.parse(url);
          final offlineUri = uri.replace(
            queryParameters: {
              ...uri.queryParameters,
              'access_type': 'offline',
              'prompt': 'consent',
            },
          );
          final ok = await launchUrl(offlineUri, mode: LaunchMode.externalApplication);
          if (!ok) {
            throw ProgressSyncException('No se pudo abrir el navegador para iniciar sesión con Google.');
          }
        },
      );
      if (client.credentials.refreshToken == null) {
        client.close();
        throw ProgressSyncException(
          'Google no devolvió un token de actualización. Vuelve a iniciar sesión y acepta el acceso.',
        );
      }
      _desktopClient?.close();
      _desktopClient = client;
      _email = await _fetchEmail(client) ?? _email;
      await _persistDesktopCredentials(client.credentials);
      if (_email != null) await _storage.write(key: _emailStorageKey, value: _email);
    } on ProgressSyncException {
      rethrow;
    } catch (e) {
      final text = e.toString().toLowerCase();
      if (text.contains('cancel') || text.contains('access_denied')) {
        throw ProgressSyncException('Inicio de sesión cancelado.', cancelled: true);
      }
      throw ProgressSyncException('No se pudo iniciar sesión con Google. Inténtalo de nuevo.');
    }
  }

  Future<void> _restoreDesktopSession(GoogleOAuthConfig config) async {
    final raw = await _storage.read(key: _credentialsStorageKey);
    _email = await _storage.read(key: _emailStorageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final credentials = _credentialsFromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (credentials.refreshToken == null || credentials.refreshToken!.isEmpty) {
        throw const FormatException('Falta refresh token');
      }
      _desktopClient = autoRefreshingClient(
        ClientId(config.desktopClientId, config.desktopClientSecret),
        credentials,
        _httpClient,
      );
    } catch (e) {
      debugPrint('GoogleDriveProgressStore: sesión de escritorio inválida: $e');
      await _storage.delete(key: _credentialsStorageKey);
      await _storage.delete(key: _emailStorageKey);
      _desktopClient = null;
      _email = null;
    }
  }

  Future<void> _persistDesktopCredentials(AccessCredentials credentials) async {
    final payload = {
      'type': credentials.accessToken.type,
      'data': credentials.accessToken.data,
      'expiry': credentials.accessToken.expiry.toIso8601String(),
      'refreshToken': credentials.refreshToken,
      'idToken': credentials.idToken,
      'scopes': credentials.scopes,
    };
    await _storage.write(key: _credentialsStorageKey, value: jsonEncode(payload));
  }

  AccessCredentials _credentialsFromJson(Map<String, dynamic> json) {
    return AccessCredentials(
      AccessToken(
        json['type']?.toString() ?? 'Bearer',
        json['data']?.toString() ?? '',
        DateTime.parse(json['expiry']?.toString() ?? DateTime.now().toIso8601String()).toUtc(),
      ),
      json['refreshToken']?.toString(),
      (json['scopes'] as List? ?? _scopes).map((e) => e.toString()).toList(),
      idToken: json['idToken']?.toString(),
    );
  }

  Future<void> _ensureMobileInitialized(GoogleOAuthConfig config) async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: config.serverClientId.isNotEmpty ? config.serverClientId : null,
    );
    _initialized = true;
  }

  Future<void> _restoreMobileSession(GoogleOAuthConfig config) async {
    await _ensureMobileInitialized(config);
    try {
      final pending = GoogleSignIn.instance.attemptLightweightAuthentication();
      _mobileAccount = pending == null ? null : await pending;
      _email = _mobileAccount?.email;
    } catch (e) {
      debugPrint('GoogleDriveProgressStore: sesión móvil no restaurada: $e');
    }
  }

  Future<void> _signInMobile(GoogleOAuthConfig config) async {
    await _ensureMobileInitialized(config);
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw ProgressSyncException(
        'El inicio de sesión con Google no está disponible en esta plataforma.',
      );
    }
    try {
      _mobileAccount = await GoogleSignIn.instance.authenticate(scopeHint: _scopes);
      _email = _mobileAccount?.email;
      await _mobileAccount!.authorizationClient.authorizeScopes(_scopes);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw ProgressSyncException('Inicio de sesión cancelado.', cancelled: true);
      }
      throw ProgressSyncException(e.description ?? 'No se pudo iniciar sesión con Google.');
    }
  }

  Future<String?> _fetchEmail(AuthClient client) async {
    try {
      final response = await client.get(Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['email']?.toString();
    } catch (e) {
      debugPrint('GoogleDriveProgressStore: no se pudo leer el email: $e');
      return null;
    }
  }
}
