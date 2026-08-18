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
    final color = progressTrafficColor(progress.ratio);

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
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
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
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: const BoxDecoration(
                  color: AppTheme.cardFooter,
                  border: Border(top: BorderSide(color: Color(0xFFD5DCE6))),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            footerLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (!progress.isEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            progress.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!progress.isEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress.ratio,
                          minHeight: 7,
                          backgroundColor: color.withValues(alpha: 0.18),
                          color: color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
