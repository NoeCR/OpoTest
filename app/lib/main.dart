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
import 'features/daily_focus/application/daily_focus_service.dart';
import 'features/failed_questions_export/application/failed_questions_collector.dart';
import 'features/failed_questions_export/application/failed_questions_export_service.dart';
import 'features/in_progress_session/data/in_progress_session_store.dart';
import 'features/random_tests/application/random_test_service.dart';
import 'features/temario_search/application/temario_search_service.dart';
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
  final inProgressSessionStore = InProgressSessionStore(db);
  final contentBackupService = ContentBackupService(ContentBackupRepositoryImpl(db));
  final progressBackupService = ProgressBackupService(ProgressBackupRepositoryImpl(db));
  final randomTestService = RandomTestService(db);
  final failedQuestionsCollector = FailedQuestionsCollector(db);
  final failedQuestionsExportService = FailedQuestionsExportService(
    failedQuestionsCollector,
  );
  final dailyFocusService = DailyFocusService(db, failedQuestionsCollector);
  final temarioSearchService = TemarioSearchService(db);
  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<CustomTestService>.value(value: customTestService),
        Provider<InProgressSessionStore>.value(value: inProgressSessionStore),
        Provider<ContentBackupService>.value(value: contentBackupService),
        Provider<ProgressBackupService>.value(value: progressBackupService),
        Provider<RandomTestService>.value(value: randomTestService),
        Provider<FailedQuestionsExportService>.value(value: failedQuestionsExportService),
        Provider<DailyFocusService>.value(value: dailyFocusService),
        Provider<TemarioSearchService>.value(value: temarioSearchService),
        ChangeNotifierProvider<TestPreferences>.value(value: testPrefs),
        ChangeNotifierProvider<AppState>.value(value: state),
      ],
      child: const OpoTestApp(),
    ),
  );
}
