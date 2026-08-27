import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/app_database.dart';
import '../features/in_progress_session/data/in_progress_session_store.dart';
import '../features/in_progress_session/domain/in_progress_choices.dart';
import '../features/in_progress_session/domain/in_progress_session.dart';
import '../features/in_progress_session/presentation/in_progress_session_dialogs.dart';
import '../models/question.dart';
import '../navigation/app_navigation.dart';
import '../screens/test_session_screen.dart';
import '../state/app_state.dart';
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

    await _open(context, test: test, prefs: prefs);
  }

  static Future<void> startWithDefinition(
    BuildContext context, {
    required TestDefinition test,
  }) async {
    final prefs = context.read<TestPreferences>();
    await _open(context, test: test, prefs: prefs);
  }

  static Future<void> resume(
    BuildContext context, {
    required InProgressSession session,
  }) {
    return _pushSession(context, session);
  }

  static Future<void> _open(
    BuildContext context, {
    required TestDefinition test,
    required TestPreferences prefs,
  }) async {
    final user = context.read<AppState>().activeUser;
    if (user == null) return;
    final store = context.read<InProgressSessionStore>();
    final existing = await store.getForUser(user.id);
    if (!context.mounted) return;

    if (existing != null) {
      if (existing.testId == test.id) {
        await _pushSession(context, existing);
        return;
      }
      final choice = await showInProgressConflictDialog(context, existing: existing);
      if (!context.mounted) return;
      switch (choice) {
        case InProgressStartChoice.resume:
          await _pushSession(context, existing);
          return;
        case InProgressStartChoice.replace:
          await store.deleteForUser(user.id);
          if (!context.mounted) return;
          break;
        case InProgressStartChoice.cancel:
          return;
      }
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

  static Future<void> _pushSession(BuildContext context, InProgressSession session) async {
    final test = session.test;
    if (test.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo recuperar el test a medias.')),
      );
      await context.read<InProgressSessionStore>().deleteForUser(session.userId);
      return;
    }

    if (!context.mounted) return;
    await context.pushPage(
      TestSessionScreen(
        test: test,
        errorFormat: session.errorFormat,
        durationMinutes: session.durationMinutes,
        examSimulation: session.examSimulation,
        initialAnswers: session.answers,
        initialIndex: session.currentIndex.clamp(0, test.questions.length - 1),
        initialElapsed: session.elapsedSeconds,
      ),
      transition: AppTransition.fade,
    );
  }
}
