import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'database/app_database.dart';
import 'features/backup/application/content_backup_service.dart';
import 'features/backup/application/progress_backup_service.dart';
import 'features/backup/data/content_backup_repository_impl.dart';
import 'features/backup/data/progress_backup_repository_impl.dart';
import 'features/custom_tests/application/custom_test_service.dart';
import 'features/custom_tests/data/custom_test_repository_impl.dart';
import 'features/progress_sync/application/progress_sync_service.dart';
import 'features/progress_sync/data/progress_cloud_store_factory.dart';
import 'features/random_tests/application/random_test_service.dart';
import 'services/test_preferences.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  await AppDatabase.init();
  final testPrefs = TestPreferences();
  await testPrefs.load();
  final state = AppState(db);
  await state.bootstrap();
  final customTestService = CustomTestService(CustomTestRepositoryImpl(db));
  final contentBackupService = ContentBackupService(ContentBackupRepositoryImpl(db));
  final progressBackupRepository = ProgressBackupRepositoryImpl(db);
  final progressBackupService = ProgressBackupService(progressBackupRepository);
  final progressSyncService = ProgressSyncService(
    backupRepository: progressBackupRepository,
    store: createProgressCloudStore(),
    onProgressImported: state.notifyProgressChanged,
  );
  final randomTestService = RandomTestService(db);
  await progressSyncService.restoreSession();
  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<CustomTestService>.value(value: customTestService),
        Provider<ContentBackupService>.value(value: contentBackupService),
        Provider<ProgressBackupService>.value(value: progressBackupService),
        ChangeNotifierProvider<ProgressSyncService>.value(value: progressSyncService),
        Provider<RandomTestService>.value(value: randomTestService),
        ChangeNotifierProvider<TestPreferences>.value(value: testPrefs),
        ChangeNotifierProvider<AppState>.value(value: state),
      ],
      child: const OpoTestApp(),
    ),
  );
  unawaited(progressSyncService.syncIfSignedIn());
}
