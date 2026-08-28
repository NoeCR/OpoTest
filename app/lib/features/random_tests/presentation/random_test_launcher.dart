import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/test_launcher.dart';
import '../../../services/test_preferences.dart';
import '../../../state/app_state.dart';
import '../application/random_test_service.dart';
import '../domain/random_test_constants.dart';
import '../domain/random_test_mode.dart';

class RandomTestLauncher {
  RandomTestLauncher._();

  static Future<void> launchMode(BuildContext context, RandomTestMode mode) async {
    final messenger = ScaffoldMessenger.of(context);
    final user = context.read<AppState>().activeUser;
    if (user == null) return;

    final pick = await context.read<RandomTestService>().pick(mode: mode, userId: user.id);
    if (!context.mounted) return;

    if (pick.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(pick.emptyMessage!)));
      return;
    }

    if (pick.testId != null) {
      await TestLauncher.start(context, testId: pick.testId!);
    } else if (pick.mixedTest != null) {
      await TestLauncher.startWithDefinition(context, test: pick.mixedTest!);
    }
  }

  static Future<void> launchSimulacrum(
    BuildContext context, {
    Set<String>? includedTestIds,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final user = context.read<AppState>().activeUser;
    if (user == null) return;

    final prefs = context.read<TestPreferences>();
    final pick = await context.read<RandomTestService>().pickSimulacrum(
          userId: user.id,
          questionCount: prefs.simulacrumQuestions,
          includedTestIds: includedTestIds,
        );
    if (!context.mounted) return;

    if (pick.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(pick.emptyMessage!)));
      return;
    }

    if (pick.mixedTest != null) {
      await TestLauncher.startWithDefinition(
        context,
        test: pick.mixedTest!,
        durationMinutes: prefs.simulacrumMinutes,
        examSimulation: true,
        errorFormat: RandomTestConstants.simulacrumErrorFormat,
      );
    }
  }
}
