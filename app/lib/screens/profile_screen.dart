import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';
import '../navigation/app_navigation.dart';
import '../features/backup/application/progress_backup_service.dart';
import '../features/backup/presentation/backup_share.dart';
import '../features/score_trend/application/score_trend_service.dart';
import '../features/score_trend/domain/score_trend.dart';
import '../features/score_trend/presentation/score_trend_card.dart';
import '../features/profile_sync/presentation/profile_sync_screen.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/user_facing_error.dart';
import '../widgets/app_decorations.dart';
import '../widgets/score_stars.dart';
import 'settings_screen.dart';
import 'test_history_screen.dart';
import 'users_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _attemptCount = 0;
  double? _avgPercent;
  ScoreTrend? _trend;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final userId = context.read<AppState>().activeUser?.id;
    if (userId == null) return;
    final db = context.read<AppDatabase>();
    final rows = await context.read<AppState>().attemptsForUser(userId);
    final trend = await ScoreTrendService(db).forUser(userId: userId);
    if (!mounted) return;
    var sum = 0.0;
    for (final r in rows) {
      sum += (r['percent_score'] as num?)?.toDouble() ?? 0;
    }
    setState(() {
      _attemptCount = rows.length;
      _avgPercent = rows.isEmpty ? null : sum / rows.length;
      _trend = trend;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.activeUser!;

    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const GradientHeader(title: 'Perfil', subtitle: 'Cuenta local · sincronización opcional'),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (_attemptCount > 0) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _StatChip(label: 'Intentos', value: '$_attemptCount')),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatChip(
                          label: 'Media',
                          value: _avgPercent != null ? '${_avgPercent!.round()}%' : '—',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          children: [
                            ScoreStars(percent: _avgPercent, size: 14),
                            const SizedBox(height: 4),
                            const Text('Estrellas', style: TextStyle(fontSize: 11, color: Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (_trend != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ScoreTrendCard(trend: _trend!),
            ),
          ],
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
          _ProfileTile(
            icon: Icons.swap_horiz,
            title: 'Cambiar usuario',
            subtitle: 'Crear o seleccionar otra cuenta local',
            onTap: () async {
              await context.pushPage(const UsersScreen());
              _loadStats();
            },
          ),
          _ProfileTile(
            icon: Icons.cloud_sync_outlined,
            title: 'Sincronizar este perfil',
            subtitle: 'Mismo progreso en tablet, móvil y PC, sin mezclar otras cuentas',
            onTap: () async {
              await context.pushPage(const ProfileSyncScreen());
              _loadStats();
            },
          ),
          _ProfileTile(
            icon: Icons.share_outlined,
            title: 'Exportar y compartir progreso',
            subtitle: 'Enviar el JSON a Drive, correo u otra app',
            onTap: () async {
              try {
                final user = state.activeUser!;
                final result = await context.read<ProgressBackupService>().exportUser(user: user);
                if (!context.mounted) return;
                final status = await shareBackupFile(
                  context,
                  filePath: result.filePath,
                  shareName: result.shareName,
                );
                if (!context.mounted) return;
                if (status == ShareResultStatus.unavailable) {
                  await _showExportedPathDialog(context, result.filePath, result.stats);
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(UserFacingError.message(e, context: UserErrorContext.backup)),
                  ),
                );
              }
            },
          ),
          _ProfileTile(
            icon: Icons.history_outlined,
            title: 'Historial',
            subtitle: 'Tests completados, notas y fechas',
            onTap: () async {
              await context.pushPage(const TestHistoryScreen());
              _loadStats();
            },
          ),
          _ProfileTile(
            icon: Icons.settings_outlined,
            title: 'Configuración',
            subtitle: 'Importar temario · sync',
            onTap: () async {
              await context.pushPage(const SettingsScreen());
              _loadStats();
            },
          ),
          if (state.lastImport != null) ...[
            const SizedBox(height: 16),
            FutureBuilder<int>(
              future: context.read<AppDatabase>().countQuestions(),
              builder: (context, snap) {
                final q = snap.data;
                return Text(
                  '${state.laws.length} leyes · ${state.lastImport!.tests} tests'
                  '${q != null ? ' · $q preguntas' : ''}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                );
              },
            ),
          ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportedPathDialog(
    BuildContext context,
    String filePath,
    Map<String, dynamic> stats,
  ) {
    return showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Progreso exportado'),
        content: SelectableText(
          (stats['total_attempts'] as int? ?? 0) == 0
              ? 'Archivo creado (sin intentos aún):\n$filePath'
              : 'Intentos: ${stats['total_attempts']}\n'
                  'Tests distintos: ${stats['unique_tests']}\n'
                  'Media: ${stats['average_percent']}%\n'
                  'Mejor: ${stats['best_percent']}%\n\n'
                  '$filePath',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cerrar')),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: AppDecorations.card(),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppDecorations.card(),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black26),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
