import 'package:flutter/material.dart';

import '../models/test_stats.dart';
import '../theme/app_theme.dart';
import 'score_stars.dart';

class TestPickerCard extends StatelessWidget {
  const TestPickerCard({
    super.key,
    required this.index,
    required this.stats,
    required this.onTap,
  });

  final int index;
  final TestStats stats;
  final VoidCallback onTap;

  String get _attemptsLabel {
    if (stats.attempts <= 0) return 'Sin realizar';
    if (stats.attempts == 1) return 'Realizado 1 vez';
    return 'Realizado ${stats.attempts} veces';
  }

  @override
  Widget build(BuildContext context) {
    final done = stats.attempts > 0;

    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  Text(
                    'TEST',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w800,
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (done ? const Color(0xFF2EAD5B) : AppTheme.primary).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${stats.attempts}x',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: done ? const Color(0xFF1B7A3D) : AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.cardDark,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              decoration: const BoxDecoration(
                color: AppTheme.cardFooter,
                border: Border(top: BorderSide(color: Color(0xFFD5DCE6))),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _StarStat(label: 'Nota media', percent: stats.avgPercent)),
                      Expanded(child: _StarStat(label: 'Mejor nota', percent: stats.bestPercent)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _attemptsLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarStat extends StatelessWidget {
  const _StarStat({required this.label, required this.percent});

  final String label;
  final double? percent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.black54), textAlign: TextAlign.center),
        const SizedBox(height: 2),
        ScoreStars(percent: percent, size: 13, showLabel: true),
      ],
    );
  }
}

class TestPickerGrid extends StatelessWidget {
  const TestPickerGrid({
    super.key,
    required this.ids,
    required this.stats,
    required this.onOpen,
    this.emptyLabel = 'No hay tests en esta sección',
  });

  final List<String> ids;
  final Map<String, TestStats> stats;
  final Future<void> Function(String testId) onOpen;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) {
      return Center(child: Text(emptyLabel, textAlign: TextAlign.center));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: ids.length,
      itemBuilder: (context, i) {
        final id = ids[i];
        return TestPickerCard(
          index: i + 1,
          stats: stats[id] ?? const TestStats(),
          onTap: () => onOpen(id),
        );
      },
    );
  }
}
