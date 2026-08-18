import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/qmap.dart';

Color progressTrafficColor(double ratio) {
  if (ratio >= 0.67) return const Color(0xFF2EAD5B);
  if (ratio >= 0.34) return const Color(0xFFE6A817);
  return const Color(0xFFE53935);
}

class TopicProgressCard extends StatelessWidget {
  const TopicProgressCard({
    super.key,
    required this.title,
    required this.footerLabel,
    required this.progress,
    required this.onTap,
  });

  final String title;
  final String footerLabel;
  final ProgressCounts progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final barColor = progressTrafficColor(progress.ratio);
    final subtitle = footerLabel.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(18, 18, 18, subtitle.isEmpty && progress.isEmpty ? 18 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.cardDark,
                              height: 1.25,
                            ),
                          ),
                        ),
                        if (!progress.isEmpty) ...[
                          const SizedBox(width: 10),
                          _ProgressBadge(label: progress.label),
                        ],
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!progress.isEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  decoration: const BoxDecoration(
                    color: AppTheme.cardFooter,
                    border: Border(top: BorderSide(color: Color(0xFFD5DCE6))),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress.ratio,
                        minHeight: 7,
                        backgroundColor: barColor.withValues(alpha: 0.18),
                        color: barColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.cardDark,
        ),
      ),
    );
  }
}
