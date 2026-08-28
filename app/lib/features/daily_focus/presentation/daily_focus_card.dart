import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_decorations.dart';
import '../domain/daily_focus.dart';

class DailyFocusCard extends StatelessWidget {
  const DailyFocusCard({
    super.key,
    required this.plan,
    required this.onSelect,
    this.compact = false,
  });

  final DailyFocusPlan plan;
  final ValueChanged<DailyFocusAction> onSelect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.card(),
      padding: EdgeInsets.all(compact ? 14 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('HOY', style: AppDecorations.sectionLabel(context)),
          const SizedBox(height: 4),
          const Text(
            'Elige qué practicar',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < plan.actions.length; i++) ...[
            if (i == 1) ...[
              const SizedBox(height: 4),
              Text('También', style: AppDecorations.sectionLabel(context)),
              const SizedBox(height: 8),
            ] else if (i > 0)
              const SizedBox(height: 8),
            _FocusOptionTile(
              action: plan.actions[i],
              recommended: i == 0,
              compact: compact,
              onSelect: onSelect,
            ),
          ],
        ],
      ),
    );
  }
}

class _FocusOptionTile extends StatelessWidget {
  const _FocusOptionTile({
    required this.action,
    required this.recommended,
    required this.compact,
    required this.onSelect,
  });

  final DailyFocusAction action;
  final bool recommended;
  final bool compact;
  final ValueChanged<DailyFocusAction> onSelect;

  IconData get _icon => switch (action.kind) {
        DailyFocusKind.markedReview => Icons.bookmark_rounded,
        DailyFocusKind.reinforcement => Icons.fitness_center_rounded,
        DailyFocusKind.weakTest => Icons.trending_down_rounded,
        DailyFocusKind.retryLast => Icons.replay_rounded,
        DailyFocusKind.classic => Icons.shuffle_rounded,
        DailyFocusKind.getStarted => Icons.download_rounded,
      };

  Color get _iconColor => switch (action.kind) {
        DailyFocusKind.markedReview => AppTheme.accentOrange,
        DailyFocusKind.reinforcement => Colors.deepOrange.shade400,
        DailyFocusKind.weakTest => Colors.red.shade400,
        DailyFocusKind.retryLast => AppTheme.primary,
        DailyFocusKind.classic => AppTheme.accentPurple,
        DailyFocusKind.getStarted => AppTheme.primary,
      };

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 18.0 : 20.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(action),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: recommended ? AppTheme.primary.withValues(alpha: 0.06) : const Color(0xFFF7F8FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: recommended ? AppTheme.primary.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 10 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: compact ? 36 : 40,
                      height: compact ? 36 : 40,
                      decoration: BoxDecoration(
                        color: _iconColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_icon, size: iconSize, color: _iconColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (recommended)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 2),
                              child: Text(
                                'RECOMENDADO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          Text(
                            action.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            action.reason,
                            style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    if (!recommended) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, color: Colors.black.withValues(alpha: 0.35)),
                    ],
                  ],
                ),
                if (recommended) ...[
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () => onSelect(action),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Empezar'),
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
