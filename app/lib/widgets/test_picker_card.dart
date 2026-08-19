import 'package:flutter/material.dart';

import '../models/test_stats.dart';
import '../theme/app_theme.dart';
import 'score_stars.dart';

Color scoreAccentColor(double? percent) {
  if (percent == null) return const Color(0xFF6B7280);
  if (percent >= 100) return const Color(0xFF15803D);
  if (percent >= 67) return const Color(0xFF2EAD5B);
  if (percent >= 34) return const Color(0xFFB45309);
  return const Color(0xFFC62828);
}

class TestPickerCard extends StatelessWidget {
  const TestPickerCard({
    super.key,
    required this.index,
    required this.stats,
    required this.onTap,
    this.compact = false,
  });

  final int index;
  final TestStats stats;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final done = stats.hasAttempts;
    final perfect = stats.lastPerfect;
    final accent = scoreAccentColor(stats.displayPercent);
    final borderColor = perfect
        ? const Color(0xFF15803D)
        : done
            ? accent.withValues(alpha: 0.35)
            : const Color(0xFFD5DCE6);

    return Semantics(
      button: true,
      label: _semanticsLabel,
      child: Material(
        color: perfect ? const Color(0xFFF0FDF4) : Colors.white,
        elevation: perfect ? 2 : 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor, width: perfect ? 2 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(
                  children: [
                    Text(
                      'TEST',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                    const Spacer(),
                    if (perfect)
                      _PerfectBadge()
                    else
                      _AttemptsBadge(attempts: stats.attempts, done: done),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: compact ? 30 : 40,
                        fontWeight: FontWeight.w800,
                        color: done ? AppTheme.cardDark : const Color(0xFF9CA3AF),
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                decoration: BoxDecoration(
                  color: perfect ? const Color(0xFFDCFCE7) : AppTheme.cardFooter,
                  border: Border(
                    top: BorderSide(
                      color: perfect ? const Color(0xFFBBF7D0) : const Color(0xFFD5DCE6),
                    ),
                  ),
                ),
                child: done ? _DoneFooter(stats: stats, accent: accent) : const _PendingFooter(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _semanticsLabel {
    final base = 'Test ${index.toString().padLeft(2, '0')}';
    if (!stats.hasAttempts) return '$base, sin realizar';
    if (stats.lastPerfect) return '$base, último intento perfecto al cien por cien';
    return '$base, último ${stats.lastLabel}, mejor ${stats.bestLabel}, media ${stats.avgLabel}, '
        '${stats.attempts} intentos';
  }
}

class _PerfectBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF15803D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 13, color: Colors.white),
          SizedBox(width: 4),
          Text(
            '100%',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _AttemptsBadge extends StatelessWidget {
  const _AttemptsBadge({required this.attempts, required this.done});

  final int attempts;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (done ? const Color(0xFF374151) : AppTheme.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        done ? '${attempts}x' : 'Nuevo',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: done ? const Color(0xFF374151) : AppTheme.primary,
        ),
      ),
    );
  }
}

class _DoneFooter extends StatelessWidget {
  const _DoneFooter({required this.stats, required this.accent});

  final TestStats stats;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScoreStars(percent: stats.displayPercent, size: 15),
            const SizedBox(width: 8),
            Text(
              stats.lastLabel,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: accent,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Último intento',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.55),
            letterSpacing: 0.2,
          ),
        ),
        if (stats.attempts > 1) ...[
          const SizedBox(height: 6),
          Text(
            'Mejor ${stats.bestLabel} · Media ${stats.avgLabel}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.65),
            ),
          ),
        ],
      ],
    );
  }
}

class _PendingFooter extends StatelessWidget {
  const _PendingFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.play_circle_outline_rounded, size: 22, color: AppTheme.primary.withValues(alpha: 0.85)),
        const SizedBox(height: 4),
        Text(
          'Sin realizar',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black.withValues(alpha: 0.55),
          ),
        ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final SliverGridDelegate gridDelegate;

        if (width < 520) {
          gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
          );
        } else {
          final extent = width < 900 ? 176.0 : 168.0;
          gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: extent,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: width >= 900 ? 1.05 : 0.94,
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: gridDelegate,
          itemCount: ids.length,
          itemBuilder: (context, i) {
            final id = ids[i];
            return TestPickerCard(
              index: i + 1,
              stats: stats[id] ?? const TestStats(),
              compact: width >= 520,
              onTap: () => onOpen(id),
            );
          },
        );
      },
    );
  }
}
