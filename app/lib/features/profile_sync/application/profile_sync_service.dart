import 'package:uuid/uuid.dart';

import '../../../database/app_database.dart';
import '../../../features/backup/domain/backup_repository.dart';
import '../../../features/backup/domain/backup_validation.dart';
import '../../../models/local_user.dart';
import '../data/profile_sync_settings.dart';
import '../domain/profile_sync_code.dart';
import '../domain/profile_sync_link.dart';
import '../domain/profile_sync_repository.dart';
import '../domain/progress_sync_merger.dart';

class ProfileSyncService {
  ProfileSyncService({
    required AppDatabase db,
    required ProgressBackupRepository progressRepository,
    required Future<ProfileSyncRepository?> Function() openRepository,
    ProfileSyncSettings? settings,
    ProgressSyncMerger merger = const ProgressSyncMerger(),
    Duration minInterval = const Duration(seconds: 90),
  })  : _db = db,
        _progressRepository = progressRepository,
        _openRepository = openRepository,
        _settings = settings ?? ProfileSyncSettings(),
        _merger = merger,
        _minInterval = minInterval;

  final AppDatabase _db;
  final ProgressBackupRepository _progressRepository;
  final Future<ProfileSyncRepository?> Function() _openRepository;
  final ProfileSyncSettings _settings;
  final ProgressSyncMerger _merger;
  final Duration _minInterval;
  final _uuid = const Uuid();
  var _busy = false;

  Future<ProfileSyncLink?> linkFor(String userId) => _db.profileSyncLinkForUser(userId);

  Future<String> mongoUri() => _settings.mongoUri();

  Future<String> mongoUriOverride() => _settings.mongoUriOverride();

  bool get hasBundledUri => ProfileSyncSettings.hasCompiledUri;

  Future<void> setMongoUri(String value) => _settings.setMongoUri(value);

  Future<ProfileSyncCode> enableFor(LocalUser user) async {
    final existing = await _db.profileSyncLinkForUser(user.id);
    if (existing != null) {
      return ProfileSyncCode(syncId: existing.syncId, token: existing.token);
    }
    final code = ProfileSyncCode(syncId: _hex32(), token: _hex32());
    await _db.upsertProfileSyncLink(
      ProfileSyncLink(userId: user.id, syncId: code.syncId, token: code.token),
    );
    return code;
  }

  Future<void> joinWithCode({required LocalUser user, required String rawCode}) async {
    final existing = await _db.profileSyncLinkForUser(user.id);
    if (existing != null) {
      throw ProfileSyncException('Este usuario ya está vinculado. Desvincula antes de usar otro código.');
    }
    final code = ProfileSyncCode.parse(rawCode);
    final taken = await _db.profileSyncLinkForSyncId(code.syncId);
    if (taken != null && taken.userId != user.id) {
      throw ProfileSyncException('Ese código ya está vinculado a otra cuenta de este dispositivo.');
    }
    await _db.upsertProfileSyncLink(
      ProfileSyncLink(userId: user.id, syncId: code.syncId, token: code.token),
    );
  }

  Future<void> unlink(String userId) => _db.deleteProfileSyncLink(userId);

  Future<ProfileSyncResult> syncUser(
    LocalUser user, {
    bool force = false,
  }) async {
    if (_busy) return ProfileSyncResult.skipped;
    _busy = true;
    try {
      final link = await _db.profileSyncLinkForUser(user.id);
      if (link == null) return ProfileSyncResult.skipped;

      final ProfileSyncRepository? remote;
      try {
        remote = await _openRepository();
      } on ProfileSyncException catch (e) {
        await _db.upsertProfileSyncLink(
          ProfileSyncLink(
            userId: link.userId,
            syncId: link.syncId,
            token: link.token,
            lastSyncedAt: link.lastSyncedAt,
            lastError: e.message,
          ),
        );
        return ProfileSyncResult(status: ProfileSyncStatus.error, message: e.message);
      }

      if (remote == null) {
        await _db.upsertProfileSyncLink(
          ProfileSyncLink(
            userId: link.userId,
            syncId: link.syncId,
            token: link.token,
            lastSyncedAt: link.lastSyncedAt,
            lastError: 'Falta la URI de Atlas en Configuración.',
          ),
        );
        return ProfileSyncResult.disabled;
      }

      if (!force &&
          link.lastSyncedAt != null &&
          DateTime.now().difference(link.lastSyncedAt!) < _minInterval) {
        return ProfileSyncResult.skipped;
      }

      try {
        final localPayload = await _progressRepository.buildExportPayload(userId: user.id);
        final remoteSnap = await remote.getProfile(syncId: link.syncId, token: link.token);
        if (remoteSnap != null) {
          validateProgressBackup(remoteSnap.payload);
        }
        final merged = _merger.merge(
          local: localPayload,
          remote: remoteSnap?.payload ?? const {},
          userId: user.id,
          displayName: user.name,
          createdAt: user.createdAt,
        );
        await _db.mergeProgressForUser(userId: user.id, payload: merged);

        final cloudPayload = _merger.remapToUser(
          merged,
          userId: link.syncId,
          displayName: user.name,
          createdAt: user.createdAt,
        );
        cloudPayload.remove('active_user_id');
        cloudPayload.remove('summary');
        cloudPayload.remove('by_test');

        final now = DateTime.now().toUtc();
        await remote.putProfile(
          syncId: link.syncId,
          token: link.token,
          updatedAt: now,
          payload: cloudPayload,
        );
        await _db.upsertProfileSyncLink(
          ProfileSyncLink(
            userId: link.userId,
            syncId: link.syncId,
            token: link.token,
            lastSyncedAt: now,
          ),
        );
        return const ProfileSyncResult(status: ProfileSyncStatus.synced);
      } catch (e) {
        final message = e is ProfileSyncException ? e.message : e.toString();
        await _db.upsertProfileSyncLink(
          ProfileSyncLink(
            userId: link.userId,
            syncId: link.syncId,
            token: link.token,
            lastSyncedAt: link.lastSyncedAt,
            lastError: message,
          ),
        );
        return ProfileSyncResult(status: ProfileSyncStatus.error, message: message);
      }
    } finally {
      _busy = false;
    }
  }

  String _hex32() => _uuid.v4().replaceAll('-', '');
}
