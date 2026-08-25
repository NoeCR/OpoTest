import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/app_constants.dart';
import 'package:opotest/features/backup/domain/backup_constants.dart';
import 'package:opotest/features/backup/domain/backup_repository.dart';
import 'package:opotest/features/progress_sync/application/progress_sync_service.dart';
import 'package:opotest/features/progress_sync/domain/progress_cloud_store.dart';
import 'package:opotest/features/progress_sync/domain/progress_sync_exception.dart';

void main() {
  group('ProgressSyncService', () {
    test('baja, fusiona sin active_user_id y vuelve a subir', () async {
      final remote = {
        'app': AppConstants.id,
        'kind': progressBackupKind,
        'version': progressBackupVersion,
        'users': [
          {'id': 'u1', 'name': 'Ana', 'created_at': '2026-01-01T00:00:00.000'},
        ],
        'active_user_id': 'should-not-apply',
        'attempts': [
          {
            'id': 'a1',
            'user_id': 'u1',
            'test_id': '1001',
            'test_name': 'Demo',
            'finished_at': '2026-08-01T10:00:00.000',
            'duration_seconds': 60,
            'net_score': 8,
            'percent_score': 80,
            'exam_simulation': false,
            'error_format': 100,
            'answers': {'0': 1},
          },
        ],
      };
      final repo = _FakeBackupRepository(local: {
        'app': AppConstants.id,
        'kind': progressBackupKind,
        'version': progressBackupVersion,
        'users': remote['users'],
        'attempts': [],
      });
      final store = _FakeCloudStore(remote: remote, email: 'ana@gmail.com');
      var imported = false;
      final service = ProgressSyncService(
        backupRepository: repo,
        store: store,
        onProgressImported: () => imported = true,
      );

      await store.signIn();
      final result = await service.syncNow();

      expect(imported, isTrue);
      expect(result!.downloaded, isTrue);
      expect(result.uploaded, isTrue);
      expect(result.importedAttempts, 1);
      expect(repo.lastImported!.containsKey('active_user_id'), isFalse);
      expect(repo.lastReplaceExistingUsers, isFalse);
      expect(store.uploaded, isNotNull);
      expect(store.uploaded!['kind'], progressBackupKind);
    });

    test('si Drive está vacío solo sube el progreso local', () async {
      final store = _FakeCloudStore(email: 'ana@gmail.com');
      await store.signIn();
      var imported = false;
      final service = ProgressSyncService(
        backupRepository: _FakeBackupRepository(local: {
          'app': AppConstants.id,
          'kind': progressBackupKind,
          'version': progressBackupVersion,
        }),
        store: store,
        onProgressImported: () => imported = true,
      );

      final result = await service.syncNow();

      expect(imported, isFalse);
      expect(result!.downloaded, isFalse);
      expect(result.uploaded, isTrue);
      expect(store.uploaded, isNotNull);
    });

    test('sin sesión lanza error claro', () async {
      final service = ProgressSyncService(
        backupRepository: _FakeBackupRepository(local: {}),
        store: _FakeCloudStore(),
      );
      expect(
        () => service.syncNow(),
        throwsA(isA<ProgressSyncException>()),
      );
    });
  });
}

class _FakeCloudStore implements ProgressCloudStore {
  _FakeCloudStore({this.remote, this.email});

  Map<String, dynamic>? remote;
  Map<String, dynamic>? uploaded;
  @override
  String? email;
  var signedIn = false;

  @override
  bool get isSignedIn => signedIn;

  @override
  Future<void> restoreSession() async {}

  @override
  Future<void> signIn() async {
    signedIn = true;
  }

  @override
  Future<void> signOut() async {
    signedIn = false;
  }

  @override
  Future<Map<String, dynamic>?> downloadProgress() async => remote;

  @override
  Future<void> uploadProgress(Map<String, dynamic> payload) async {
    uploaded = payload;
  }
}

class _FakeBackupRepository implements ProgressBackupRepository {
  _FakeBackupRepository({required this.local});

  final Map<String, dynamic> local;
  Map<String, dynamic>? lastImported;
  bool? lastReplaceExistingUsers;

  @override
  Future<Map<String, dynamic>> buildExportPayload({String? userId}) async => local;

  @override
  Future<ProgressImportResult> importPayload(
    Map<String, dynamic> payload, {
    bool replaceExistingUsers = false,
  }) async {
    lastImported = payload;
    lastReplaceExistingUsers = replaceExistingUsers;
    return ProgressImportResult(
      users: (payload['users'] as List?)?.length ?? 0,
      attempts: (payload['attempts'] as List?)?.length ?? 0,
      missingTests: 0,
    );
  }
}
