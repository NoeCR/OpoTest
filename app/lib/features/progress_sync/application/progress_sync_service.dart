import 'package:flutter/foundation.dart';

import '../../backup/domain/backup_repository.dart';
import '../../backup/domain/backup_validation.dart';
import '../domain/progress_cloud_store.dart';
import '../domain/progress_sync_exception.dart';

class ProgressSyncResult {
  const ProgressSyncResult({
    required this.email,
    required this.downloaded,
    required this.uploaded,
    this.importedAttempts = 0,
  });

  final String? email;
  final bool downloaded;
  final bool uploaded;
  final int importedAttempts;

  String get message {
    if (!downloaded && uploaded) {
      return 'Progreso subido a Google Drive'
          '${email == null || email!.isEmpty ? '.' : ' ($email).'}';
    }
    return 'Progreso sincronizado'
        '${email == null || email!.isEmpty ? '' : ' ($email)'}'
        '${importedAttempts == 0 ? '.' : importedAttempts == 1 ? ': 1 intento fusionado' : ': $importedAttempts intentos fusionados'}';
  }
}

class ProgressSyncService extends ChangeNotifier {
  ProgressSyncService({
    required ProgressBackupRepository backupRepository,
    required ProgressCloudStore store,
    VoidCallback? onProgressImported,
  })  : _backupRepository = backupRepository,
        _store = store,
        _onProgressImported = onProgressImported;

  final ProgressBackupRepository _backupRepository;
  final ProgressCloudStore _store;
  final VoidCallback? _onProgressImported;

  var _ready = false;
  var _busy = false;

  bool get isReady => _ready;
  bool get isBusy => _busy;
  bool get isSignedIn => _store.isSignedIn;
  String? get email => _store.email;

  Future<void> restoreSession() async {
    await _store.restoreSession();
    _ready = true;
    notifyListeners();
  }

  Future<ProgressSyncResult?> signInAndSync() async {
    return _run(() async {
      await _store.signIn();
      notifyListeners();
      return _syncLocked();
    });
  }

  Future<ProgressSyncResult?> syncNow() async {
    return _run(_syncLocked);
  }

  Future<void> syncIfSignedIn() async {
    if (!_store.isSignedIn) return;
    try {
      await syncNow();
    } catch (e) {
      debugPrint('ProgressSyncService.syncIfSignedIn: $e');
    }
  }

  Future<void> signOut() async {
    await _store.signOut();
    notifyListeners();
  }

  Future<T?> _run<T>(Future<T> Function() action) async {
    if (_busy) return null;
    _busy = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<ProgressSyncResult> _syncLocked() async {
    if (!_store.isSignedIn) {
      throw ProgressSyncException('Inicia sesión con Google para sincronizar el progreso.');
    }

    var importedAttempts = 0;
    var downloaded = false;
    final remote = await _store.downloadProgress();
    if (remote != null) {
      downloaded = true;
      remote.remove('active_user_id');
      validateProgressBackup(remote);
      final imported = await _backupRepository.importPayload(
        normalizeProgressBackup(remote),
        replaceExistingUsers: false,
      );
      importedAttempts = imported.attempts;
      _onProgressImported?.call();
    }

    final local = await _backupRepository.buildExportPayload();
    await _store.uploadProgress(local);
    return ProgressSyncResult(
      email: _store.email,
      downloaded: downloaded,
      uploaded: true,
      importedAttempts: importedAttempts,
    );
  }
}
