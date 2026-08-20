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
  final progressBackupService = ProgressBackupService(ProgressBackupRepositoryImpl(db));
  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<CustomTestService>.value(value: customTestService),
        Provider<ContentBackupService>.value(value: contentBackupService),
        Provider<ProgressBackupService>.value(value: progressBackupService),
        ChangeNotifierProvider<TestPreferences>.value(value: testPrefs),
        ChangeNotifierProvider<AppState>.value(value: state),
      ],
      child: const OpoTestApp(),
    ),
  );
}
