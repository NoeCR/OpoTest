import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../domain/failed_questions_reminder.dart';

Future<bool> showFailedQuestionsReminderDialog(
  BuildContext context, {
  required FailedQuestionsReminderInterval interval,
  required int failCount,
  int dueCount = 0,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Informe de fallos'),
        content: Text(
          failedQuestionsReminderBody(
            interval: interval,
            failCount: failCount,
            dueCount: dueCount,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ahora no'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            child: const Text('Generar informe'),
          ),
        ],
      );
    },
  );
  return result == true;
}
