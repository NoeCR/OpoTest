import 'package:flutter/material.dart';

import '../models/content_kind.dart';
import '../theme/app_theme.dart';

class ContentKindTabs extends StatelessWidget {
  const ContentKindTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ContentKind selected;
  final ValueChanged<ContentKind> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final kind in ContentKind.values) ...[
              if (kind != ContentKind.values.first) const SizedBox(width: 8),
              _TabChip(
                label: kind.label,
                selected: kind == selected,
                onTap: () => onSelected(kind),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.primary : const Color(0xFFF3F5F8),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
