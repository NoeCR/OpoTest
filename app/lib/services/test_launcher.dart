import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/app_database.dart';
import '../models/question.dart';
import '../navigation/app_navigation.dart';
import '../screens/test_session_screen.dart';
import 'test_preferences.dart';

class TestLauncher {
  TestLauncher._();

  static Future<void> start(
    BuildContext context, {
    required String testId,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final db = context.read<AppDatabase>();
    final prefs = context.read<TestPreferences>();

    final test = await db.getTest(testId);
    if (!context.mounted) return;
    if (test == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se encontró el test. Reimporta el temario.')),
      );
      return;
    }

    await context.pushPage(
      TestSessionScreen(
        test: test,
        errorFormat: prefs.errorFormat,
        durationMinutes: prefs.durationMinutes,
        examSimulation: prefs.examSimulation,
      ),
      transition: AppTransition.fade,
    );
  }

  static Future<void> startWithDefinition(
    BuildContext context, {
    required TestDefinition test,
  }) async {
    final prefs = context.read<TestPreferences>();

    await context.pushPage(
      TestSessionScreen(
        test: test,
        errorFormat: prefs.errorFormat,
        durationMinutes: prefs.durationMinutes,
        examSimulation: prefs.examSimulation,
      ),
      transition: AppTransition.fade,
    );
  }
}
