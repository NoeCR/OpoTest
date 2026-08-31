import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_decorations.dart';
import '../domain/daily_streak.dart';

const _doneGreen = Color(0xFF2E7D32);
const _doneFill = Color(0xFFE8F5E9);

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
          decoration: AppDecorations.card(color: met ? _doneFill : null).copyWith(
            border: met
                ? Border.all(color: _doneGreen.withValues(alpha: 0.35))
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 16,
              vertical: compact ? 12 : 14,
            ),
            child: met ? _DoneBody(snapshot: snapshot, compact: compact) : _ProgressBody(snapshot: snapshot, compact: compact),
          ),
        ),
      ),
    );
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({required this.snapshot, required this.compact});

  final DailyStreakSnapshot snapshot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.whatshot_outlined,
              color: AppTheme.primary,
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
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
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }
}

class _DoneBody extends StatelessWidget {
  const _DoneBody({required this.snapshot, required this.compact});

  final DailyStreakSnapshot snapshot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: _doneGreen,
          size: compact ? 26 : 28,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cupo de hoy cumplido',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _doneGreen,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                snapshot.streakLabel,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
