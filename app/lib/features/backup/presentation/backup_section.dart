import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../state/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/user_facing_error.dart';
import '../../../widgets/app_decorations.dart';
import '../application/content_backup_service.dart';
import '../application/progress_backup_service.dart';
import '../data/backup_file_io.dart';
import '../domain/backup_validation.dart';
import 'backup_share.dart';

class BackupSection extends StatefulWidget {
  const BackupSection({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<BackupSection> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on BackupValidationException catch (e) {
      widget.onChanged(e.message);
    } on BackupFileCancelledException {
      widget.onChanged('Importación cancelada.');
    } catch (e) {
      widget.onChanged(UserFacingError.message(e, context: UserErrorContext.backup));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      label: 'Copias de seguridad',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Exporta o importa temario, tests y progreso para cambiar de dispositivo sin perder datos.',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.55), height: 1.35),
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(color: AppTheme.primary),
          ],
          const SizedBox(height: 12),
          Text('Contenido (leyes, tests oficiales y propios)', style: AppDecorations.sectionLabel(context)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            final result = await context.read<ContentBackupService>().export();
                            final s = result.stats;
                            if (!context.mounted) return;
                            final status = await shareBackupFile(
                              context,
                              filePath: result.filePath,
                              shareName: result.shareName,
                            );
                            if (!context.mounted) return;
                            if (status == ShareResultStatus.unavailable) {
                              widget.onChanged(
                                'Contenido exportado:\n'
                                '${s['laws'] ?? 0} leyes · ${s['titles'] ?? 0} títulos · '
                                '${s['tests_official'] ?? 0} tests oficiales · ${s['tests_custom'] ?? 0} propios\n'
                                '${result.filePath}',
                              );
                              return;
                            }
                            if (status == ShareResultStatus.success) {
                              widget.onChanged('Contenido exportado.');
                            }
                          }),
                  icon: const Icon(Icons.upload_outlined),
                  label: const Text('Exportar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            final result = await context.read<ContentBackupService>().importFromPicker();
                            widget.onChanged(
                              'Contenido importado:\n'
                              '${result.laws} leyes · ${result.titles} títulos · '
                              '${result.testsOfficial} tests oficiales · ${result.testsCustom} propios'
                              '${result.testsSkipped > 0 ? ' · ${result.testsSkipped} omitidos (custom prevalece)' : ''}',
                            );
                          }),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Importar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Progreso (todos los perfiles)', style: AppDecorations.sectionLabel(context)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            final profileName =
                                context.read<AppState>().activeUser?.name ?? 'todos-los-perfiles';
                            final result = await context.read<ProgressBackupService>().exportAll(
                                  profileName: profileName,
                                );
                            final s = result.stats;
                            if (!context.mounted) return;
                            final status = await shareBackupFile(
                              context,
                              filePath: result.filePath,
                              shareName: result.shareName,
                            );
                            if (!context.mounted) return;
                            if (status == ShareResultStatus.unavailable) {
                              widget.onChanged(
                                'Progreso exportado:\n'
                                '${s['total_attempts'] ?? 0} intentos · ${s['unique_tests'] ?? 0} tests distintos\n'
                                '${result.filePath}',
                              );
                              return;
                            }
                            if (status == ShareResultStatus.success) {
                              widget.onChanged('Progreso exportado.');
                            }
                          }),
                  icon: const Icon(Icons.upload_outlined),
                  label: const Text('Exportar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                            final progressService = context.read<ProgressBackupService>();
                            await _run(() async {
                              final replace = await _confirmReplaceUsers(context);
                              if (!mounted || replace == null) return;
                              final result = await progressService.importFromPicker(
                                replaceExistingUsers: replace,
                              );
                              widget.onChanged(
                                'Progreso importado:\n'
                                '${result.users} perfiles · ${result.attempts} intentos'
                                '${result.missingTests > 0 ? '\nAviso: ${result.missingTests} intentos referencian tests no presentes' : ''}',
                              );
                            });
                          },
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Importar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmReplaceUsers(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar progreso'),
        content: const Text(
          '¿Cómo quieres importar los perfiles?\n\n'
          '• Fusionar: añade intentos sin borrar los existentes\n'
          '• Reemplazar: borra los intentos previos de cada perfil importado',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Fusionar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reemplazar')),
        ],
      ),
    );
  }
}
