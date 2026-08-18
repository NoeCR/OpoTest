import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/test_launcher.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_decorations.dart';
import '../widgets/score_stars.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day}/${d.month}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AppState>().activeUser!.id;
    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: context.read<AppState>().attemptsForUser(userId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snap.data!;
          if (rows.isEmpty) {
            return Column(
              children: [
                const GradientHeader(title: 'Estadísticas', subtitle: 'Tu historial de tests'),
                const Expanded(
                  child: Center(child: Text('Aún no has completado ningún test')),
                ),
              ],
            );
          }

          final percents = rows.map((r) => (r['percent_score'] as num?)?.toDouble() ?? 0).toList();
          final avg = percents.reduce((a, b) => a + b) / percents.length;
          final best = percents.reduce((a, b) => a > b ? a : b);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GradientHeader(
                title: 'Estadísticas',
                subtitle: '${rows.length} intentos registrados',
                trailing: ScoreStars(percent: avg, size: 16),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryPill(label: 'Intentos', value: '${rows.length}'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryPill(label: 'Media', value: '${avg.round()}%'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryPill(label: 'Mejor', value: '${best.round()}%'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final r = rows[i];
                    final pct = (r['percent_score'] as num?)?.toDouble();
                    final net = (r['net_score'] as num?)?.toString() ?? '';
                    final duration = (r['duration_seconds'] as num?)?.toInt() ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => TestLauncher.start(
                            context,
                            testId: r['test_id'] as String,
                          ),
                          child: Ink(
                            decoration: AppDecorations.card(),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${pct?.round() ?? 0}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r['test_name'] as String? ?? 'Test',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(r['finished_at'] as String?),
                                        style: const TextStyle(color: Colors.black45, fontSize: 12),
                                      ),
                                      const SizedBox(height: 6),
                                      ScoreStars(percent: pct, size: 13),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Nota $net',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cardDark),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: const TextStyle(fontSize: 11, color: Colors.black45),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: AppDecorations.card(),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45)),
        ],
      ),
    );
  }
}
