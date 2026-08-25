import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app_constants.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/user_facing_error.dart';
import '../../../widgets/app_decorations.dart';
import '../application/progress_sync_service.dart';
import '../domain/progress_sync_exception.dart';

class GoogleSyncSection extends StatelessWidget {
  const GoogleSyncSection({super.key, this.onMessage});

  final ValueChanged<String>? onMessage;

  Future<void> _signIn(BuildContext context) async {
    final service = context.read<ProgressSyncService>();
    try {
      final result = await service.signInAndSync();
      if (!context.mounted) return;
      onMessage?.call(result?.message ?? 'Sesión iniciada con Google.');
    } on ProgressSyncException catch (e) {
      if (e.cancelled) return;
      onMessage?.call(e.message);
    } catch (e) {
      onMessage?.call(UserFacingError.message(e, context: UserErrorContext.progressSync));
    }
  }

  Future<void> _sync(BuildContext context) async {
    final service = context.read<ProgressSyncService>();
    try {
      final result = await service.syncNow();
      if (!context.mounted || result == null) return;
      onMessage?.call(result.message);
    } catch (e) {
      onMessage?.call(UserFacingError.message(e, context: UserErrorContext.progressSync));
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await context.read<ProgressSyncService>().signOut();
    onMessage?.call('Sesión de Google cerrada en este dispositivo.');
  }

  Future<void> _openHelp(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configurar Google Drive'),
        content: SingleChildScrollView(
          child: Text(
            '1. Crea un proyecto en Google Cloud y activa la API de Google Drive.\n'
            '2. Crea un ID de cliente OAuth de tipo «Aplicación de escritorio» (Windows) '
            'y otro de tipo «Aplicación web» (Android).\n'
            '3. Copia google_oauth.json.example a app/google_oauth.json y rellena los IDs.\n'
            '4. En Android, registra el package ${AppConstants.androidApplicationId} y la huella SHA-1 de firma.\n\n'
            'Los detalles están en docs/google-drive-sync.md.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ProgressSyncService>();
    final signedIn = service.isSignedIn;

    return SectionCard(
      label: 'Sincronizar con Google',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Guarda el progreso (intentos y marcas) en tu Google Drive para usarlo '
            'en Windows, tablet y móvil con la misma cuenta.',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.55), height: 1.35),
          ),
          const SizedBox(height: 12),
          if (signedIn)
            Text(
              service.email ?? 'Cuenta de Google conectada',
              style: const TextStyle(fontWeight: FontWeight.w600),
            )
          else
            const Text(
              'No hay ninguna cuenta conectada.',
              style: TextStyle(color: Colors.black54),
            ),
          if (service.isBusy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(color: AppTheme.primary),
          ],
          const SizedBox(height: 12),
          if (!signedIn)
            FilledButton.icon(
              onPressed: service.isBusy ? null : () => _signIn(context),
              icon: const Icon(Icons.login),
              label: const Text('Iniciar sesión con Google'),
            )
          else ...[
            FilledButton.icon(
              onPressed: service.isBusy ? null : () => _sync(context),
              icon: const Icon(Icons.cloud_sync_outlined),
              label: const Text('Sincronizar ahora'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: service.isBusy ? null : () => _signOut(context),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión de Google'),
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _openHelp(context),
            child: const Text('Cómo configurar Google Cloud'),
          ),
        ],
      ),
    );
  }
}
