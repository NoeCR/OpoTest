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
    final primary = plan.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(primary),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: AppDecorations.card(),
          child: Padding(
            padding: EdgeInsets.all(compact ? 14 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HOY', style: AppDecorations.sectionLabel(context)),
                const SizedBox(height: 6),
                Text(
                  primary.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  primary.reason,
                  style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.3),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: () => onSelect(primary),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Empezar'),
                  ),
                ),
                if (plan.secondary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: [
                      for (final action in plan.secondary)
                        TextButton(
                          onPressed: () => onSelect(action),
                          child: Text(action.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                    ],
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
