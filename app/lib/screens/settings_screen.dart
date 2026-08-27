import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../database/app_database.dart';
import '../models/test_options.dart';
import '../features/backup/presentation/backup_section.dart';
import '../features/failed_questions_export/application/failed_questions_export_service.dart';
import '../features/failed_questions_export/domain/failed_questions_reminder.dart';
import '../services/content_importer.dart';
import '../services/sync_service.dart';
import '../services/test_preferences.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/app_version.dart';
import '../utils/user_facing_error.dart';
import '../widgets/app_decorations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _pathController = TextEditingController();
  String? status;
  bool _importing = false;
  String? _appVersionLabel;
  FailedQuestionsReminderInterval _reminderInterval = FailedQuestionsReminderInterval.none;

  @override
  void initState() {
    super.initState();
    _loadDefaultPath();
    _loadAppVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadReminderInterval();
    });
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _appVersionLabel = formatAppVersionLabel(
          version: info.version,
          buildNumber: info.buildNumber,
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _appVersionLabel = formatAppVersionLabel(
            version: '',
            buildNumber: '',
          ));
    }
  }

  Future<void> _loadDefaultPath() async {
    try {
      final path = await ContentImporter.resolveDataPath();
      if (mounted) _pathController.text = path;
    } catch (_) {
      _pathController.text = ContentImporter.defaultDataPath();
    }
  }

  Future<void> _loadReminderInterval() async {
    final interval = await context.read<FailedQuestionsExportService>().reminderInterval();
    if (mounted) setState(() => _reminderInterval = interval);
  }

  Future<void> _setReminderInterval(FailedQuestionsReminderInterval interval) async {
    setState(() => _reminderInterval = interval);
    final service = context.read<FailedQuestionsExportService>();
    await service.setReminderInterval(interval);
    final userId = context.read<AppState>().activeUser?.id;
    if (interval != FailedQuestionsReminderInterval.none && userId != null) {
      await service.markReminderPrompted(userId);
    }
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    setState(() {
      _importing = true;
      status = 'Importando (puede tardar 1-3 min)...';
    });
    try {
      final state = context.read<AppState>();
      String dataPath;
      try {
        dataPath = await ContentImporter.resolveDataPath();
        if (mounted) _pathController.text = dataPath;
      } catch (_) {
        dataPath = _pathController.text.trim();
        if (dataPath.isEmpty) {
          setState(() => status = UserFacingError.message(
                StateError('Temario no encontrado'),
                context: UserErrorContext.import,
              ));
          return;
        }
      }
      final r = await state.importContent(dataPath);
      if (!mounted) return;
      if (r.tests == 0) {
        setState(() => status = UserFacingError.message(
              StateError('No se importó ningún test'),
              context: UserErrorContext.import,
            ));
      } else {
        setState(() => status = 'Listo: ${r.laws} leyes, ${r.titles} títulos, ${r.tests} tests');
      }
    } catch (e) {
      setState(() => status = UserFacingError.message(e, context: UserErrorContext.import));
    } finally {
      setState(() => _importing = false);
    }
  }

  Future<void> _checkSync() async {
    final sync = SyncService(context.read<AppDatabase>());
    setState(() => status = 'Comprobando versión remota...');
    try {
      final info = await sync.checkRemoteVersion();
      setState(() => status = 'Servidor: ver ${info?['ver'] ?? '?'} · sync cada ${SyncService.intervalDays} días');
    } catch (e) {
      setState(() => status = UserFacingError.message(e, context: UserErrorContext.sync));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<TestPreferences>();

    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GradientHeader(
            title: 'Configuración',
            subtitle: 'Tests, temario y sincronización',
            gradient: AppDecorations.darkHeaderGradient,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionCard(
                  label: 'Opciones de test (global)',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Los fallos restan', style: AppDecorations.sectionLabel(context)),
                      const SizedBox(height: 8),
                      OptionChipRow<int>(
                        options: TestOptions.errorFormats.keys.toList(),
                        selected: prefs.errorFormat,
                        onSelected: prefs.setErrorFormat,
                        labelBuilder: (v) => TestOptions.errorFormats[v] ?? '$v',
                      ),
                      const SizedBox(height: 16),
                      Text('Límite de tiempo', style: AppDecorations.sectionLabel(context)),
                      const SizedBox(height: 8),
                      OptionChipRow<int>(
                        options: TestOptions.durations,
                        selected: prefs.durationMinutes,
                        onSelected: prefs.setDurationMinutes,
                        labelBuilder: TestOptions.durationLabel,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Simulación de examen', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text(
                          'Oculta corrección inmediata y notas aclaratorias',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: prefs.examSimulation,
                        onChanged: prefs.setExamSimulation,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  label: 'Informe de fallos',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Recordatorio al abrir la app', style: AppDecorations.sectionLabel(context)),
                      const SizedBox(height: 8),
                      OptionChipRow<FailedQuestionsReminderInterval>(
                        options: FailedQuestionsReminderInterval.values,
                        selected: _reminderInterval,
                        onSelected: _setReminderInterval,
                        labelBuilder: (v) => v.label,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        switch (_reminderInterval) {
                          FailedQuestionsReminderInterval.none =>
                            'No se mostrará ningún aviso. Puedes exportar fallos cuando quieras desde Inicio.',
                          FailedQuestionsReminderInterval.daily =>
                            'Al día siguiente de abrir la app, si hay fallos nuevos, te preguntará si generar el informe.',
                          FailedQuestionsReminderInterval.weekly =>
                            'Pasados 7 días, si hay fallos, te preguntará si generar el informe.',
                        },
                        style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                BackupSection(onChanged: (message) => setState(() => status = message)),
                const SizedBox(height: 12),
                SectionCard(
                  label: 'Carpeta de datos',
                  child: TextField(
                    controller: _pathController,
                    decoration: const InputDecoration(
                      hintText: 'Ruta a ../data',
                      prefixIcon: Icon(Icons.folder_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_importing)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(color: AppTheme.primary),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: AppDecorations.headerGradient,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: _importing ? null : _import,
                    child: const Text('IMPORTAR TEMARIO'),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _checkSync,
                  icon: const Icon(Icons.cloud_sync_outlined),
                  label: const Text('Comprobar actualizaciones'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: AppDecorations.card(color: AppTheme.primary.withValues(alpha: 0.06)),
                    child: Text(status!, style: const TextStyle(color: Colors.black87)),
                  ),
                ],
                const SizedBox(height: 24),
                if (_appVersionLabel != null)
                  Text(
                    _appVersionLabel!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black45, height: 1.4),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
