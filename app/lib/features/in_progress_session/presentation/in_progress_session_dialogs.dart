import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../domain/in_progress_choices.dart';
import '../domain/in_progress_session.dart';

Future<InProgressLeaveChoice> showInProgressLeaveDialog(
  BuildContext context, {
  required bool hasAnswers,
}) async {
  final result = await showDialog<InProgressLeaveChoice>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('¿Pausar el test?'),
        content: const Text(
          'Puedes continuar más tarde desde Inicio. El intento no se guarda en el historial hasta que finalices.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, InProgressLeaveChoice.stay),
            child: const Text('Seguir'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, InProgressLeaveChoice.finish),
            child: Text(hasAnswers ? 'Finalizar' : 'Salir'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, InProgressLeaveChoice.pause),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            child: const Text('Pausar'),
          ),
        ],
      );
    },
  );
  return result ?? InProgressLeaveChoice.stay;
}

Future<InProgressStartChoice> showInProgressConflictDialog(
  BuildContext context, {
  required InProgressSession existing,
}) async {
  final result = await showDialog<InProgressStartChoice>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Tienes un test a medias'),
        content: Text(
          '«${existing.testName}» (${existing.progressLabel}). '
          'Si empiezas otro, se pierde el anterior.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, InProgressStartChoice.cancel),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, InProgressStartChoice.resume),
            child: const Text('Continuar el anterior'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, InProgressStartChoice.replace),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            child: const Text('Empezar este'),
          ),
        ],
      );
    },
  );
  return result ?? InProgressStartChoice.cancel;
}
