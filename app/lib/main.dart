import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'database/app_database.dart';
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
  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<CustomTestService>.value(value: customTestService),
        ChangeNotifierProvider<TestPreferences>.value(value: testPrefs),
        ChangeNotifierProvider<AppState>.value(value: state),
      ],
      child: const TesteaApp(),
    ),
  );
}
