import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_decorations.dart';
import '../domain/score_trend.dart';

class ScoreTrendCard extends StatelessWidget {
  const ScoreTrendCard({
    super.key,
    required this.trend,
  });

  final ScoreTrend trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('EVOLUCIÓN', style: AppDecorations.sectionLabel(context)),
          const SizedBox(height: 4),
          const Text(
            'Notas de tests del temario (sin aleatorios ni simulacro).',
            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.3),
          ),
          const SizedBox(height: 14),
          if (trend.isEmpty)
            const Text(
              'Haz algún test de legislación para ver la tendencia.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _WeekStat(
                    label: 'Esta semana',
                    average: trend.thisWeekAverage,
                    count: trend.thisWeekCount,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WeekStat(
                    label: 'Anterior',
                    average: trend.previousWeekAverage,
                    count: trend.previousWeekCount,
                  ),
                ),
              ],
            ),
            if (trend.weekDelta != null) ...[
              const SizedBox(height: 8),
              Text(
                _deltaLabel(trend.weekDelta!),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: trend.weekDelta! >= 0 ? Colors.green.shade700 : AppTheme.primary,
                ),
              ),
            ],
            if (trend.recentBars.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 88,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final bar in trend.recentBars) ...[
                      Expanded(
                        child: Tooltip(
                          message: '${bar.percent.round()}%',
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            height: ((bar.percent.clamp(0, 100) / 100) * 80).clamp(4, 88),
                            decoration: BoxDecoration(
                              color: _barColor(bar.percent),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Últimos tests (izquierda = más antiguo)',
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ],
        ],
      ),
    );
  }

  static String _deltaLabel(double delta) {
    final abs = delta.abs().round();
    if (delta >= 0) return 'Esta semana va $abs puntos por encima de la anterior';
    return 'Esta semana va $abs puntos por debajo de la anterior';
  }

  static Color _barColor(double percent) {
    if (percent >= 70) return const Color(0xFF43A047);
    if (percent >= 50) return AppTheme.accentOrange;
    return AppTheme.primary;
  }
}

class _WeekStat extends StatelessWidget {
  const _WeekStat({
    required this.label,
    required this.average,
    required this.count,
  });

  final String label;
  final double? average;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppDecorations.sectionLabel(context)),
        const SizedBox(height: 4),
        Text(
          average == null ? '—' : '${average!.round()}%',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87),
        ),
        Text(
          count == 0 ? 'Sin tests' : (count == 1 ? '1 test' : '$count tests'),
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
