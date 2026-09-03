import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/database/app_database.dart';
import 'package:opotest/features/backup/data/progress_backup_repository_impl.dart';
import 'package:opotest/features/profile_sync/application/profile_sync_service.dart';
import 'package:opotest/features/profile_sync/data/memory_profile_sync_repository.dart';
import 'package:opotest/features/profile_sync/domain/profile_sync_link.dart';
import 'package:opotest/features/profile_sync/domain/profile_sync_repository.dart';
import 'package:opotest/models/local_user.dart';

import '../../helpers/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MemoryProfileSyncRepository remote;
  late ProfileSyncService sync;
  late LocalUser noe;
  late LocalUser maria;

  setUp(() async {
    db = await setUpTestDatabase();
    remote = MemoryProfileSyncRepository();
    sync = ProfileSyncService(
      db: db,
      progressRepository: ProgressBackupRepositoryImpl(db),
      openRepository: () async => remote,
      minInterval: Duration.zero,
    );
    noe = LocalUser(id: 'noe', name: 'Noe', createdAt: DateTime.parse('2026-01-01'));
    maria = LocalUser(id: 'maria', name: 'Maria', createdAt: DateTime.parse('2026-01-02'));
    await db.upsertUser(noe);
    await db.upsertUser(maria);
    await db.upsertOfficialTest(sampleTestJson(id: '1001'));
  });

  tearDown(tearDownTestDatabase);

  Future<void> _saveAttempt(String id, String userId) {
    return db.saveAttempt(
      TestAttempt(
        id: id,
        userId: userId,
        testId: '1001',
        testName: 'Test demo',
        finishedAt: DateTime.parse('2026-06-01T10:00:00'),
        durationSeconds: 60,
        netScore: 8,
        percentScore: 80,
        answers: const {0: 1},
        examSimulation: false,
        errorFormat: 0,
      ),
    );
  }

  test('en el mismo dispositivo un código no se puede vincular a dos cuentas', () async {
    final code = await sync.enableFor(noe);
    await expectLater(
      () => sync.joinWithCode(user: maria, rawCode: code.compact),
      throwsA(isA<ProfileSyncException>()),
    );
    expect(await db.attemptsForUser(maria.id), isEmpty);
  });

  test('sube el progreso al remoto y no lo aplica a otra cuenta no vinculada', () async {
    final code = await sync.enableFor(noe);
    await _saveAttempt('att-noe', noe.id);
    final pushed = await sync.syncUser(noe, force: true);
    expect(pushed.status, ProfileSyncStatus.synced);

    final remoteSnap = await remote.getProfile(syncId: code.syncId, token: code.token);
    expect(remoteSnap, isNotNull);
    final remoteIds = (remoteSnap!.payload['attempts'] as List).map((r) => (r as Map)['id']);
    expect(remoteIds, contains('att-noe'));
    expect(await db.attemptsForUser(maria.id), isEmpty);
  });
}
