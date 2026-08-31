import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_decorations.dart';
import '../domain/daily_streak.dart';

class DailyStreakChip extends StatelessWidget {
  const DailyStreakChip({
    super.key,
    required this.snapshot,
    this.onTap,
    this.compact = false,
  });

  final DailyStreakSnapshot snapshot;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final met = snapshot.goalMet;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: AppDecorations.card(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 16,
              vertical: compact ? 12 : 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      met ? Icons.local_fire_department_rounded : Icons.whatshot_outlined,
                      color: met ? AppTheme.accentOrange : AppTheme.primary,
                      size: compact ? 22 : 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        snapshot.streakLabel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      snapshot.cupoLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: met ? AppTheme.primary : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: snapshot.progress,
                    minHeight: 8,
                    backgroundColor: Colors.black.withValues(alpha: 0.08),
                    color: met ? AppTheme.accentOrange : AppTheme.primary,
                  ),
                ),
                if (met) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Cupo de hoy cumplido',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
