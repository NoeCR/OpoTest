import 'package:flutter/material.dart';

import '../models/law_sort_mode.dart';
import '../theme/app_theme.dart';

class LawSortBar extends StatelessWidget {
  const LawSortBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.customOrderLocked = true,
    this.onToggleCustomLock,
  });

  final LawSortMode selected;
  final ValueChanged<LawSortMode> onSelected;
  final bool customOrderLocked;
  final VoidCallback? onToggleCustomLock;

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<LawSortMode>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    'Ordenar legislación',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                for (final mode in LawSortMode.values)
                  ListTile(
                    title: Text(
                      mode.label,
                      style: TextStyle(
                        fontWeight: mode == selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    trailing: mode == selected
                        ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                        : null,
                    onTap: () => Navigator.pop(ctx, mode),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final showLock = selected == LawSortMode.custom;
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _openPicker(context),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Row(
                    children: [
                      Icon(Icons.sort_rounded, size: 20, color: Colors.black.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      Text(
                        'Orden',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withValues(alpha: 0.7),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selected.label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.expand_more_rounded, size: 18, color: AppTheme.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (showLock)
              IconButton(
                tooltip: customOrderLocked ? 'Desbloquear para reordenar' : 'Bloquear orden',
                onPressed: onToggleCustomLock,
                icon: Icon(
                  customOrderLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                  color: customOrderLocked ? Colors.black54 : AppTheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
