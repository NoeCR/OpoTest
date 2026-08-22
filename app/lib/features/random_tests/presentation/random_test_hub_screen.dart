import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_decorations.dart';
import '../../../services/test_launcher.dart';
import '../application/random_test_service.dart';
import '../domain/random_test_mode.dart';

class RandomTestHubScreen extends StatelessWidget {
  const RandomTestHubScreen({super.key});

  Future<void> _launchMode(BuildContext context, RandomTestMode mode) async {
    final messenger = ScaffoldMessenger.of(context);
    final user = context.read<AppState>().activeUser;
    if (user == null) return;

    final service = context.read<RandomTestService>();
    final pick = await service.pick(mode: mode, userId: user.id);
    if (!context.mounted) return;

    if (pick.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(pick.emptyMessage!)));
      return;
    }

    if (pick.testId != null) {
      await TestLauncher.start(context, testId: pick.testId!);
    } else if (pick.mixedTest != null) {
      await TestLauncher.startWithDefinition(context, test: pick.mixedTest!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      appBar: AppBar(
        title: const Text('Test aleatorio'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary.withValues(alpha: 0.9), AppTheme.cardDark.withValues(alpha: 0.95)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Elige cómo quieres practicar',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          const SizedBox(height: 12),
          for (final mode in RandomTestMode.values) ...[
            _ModeTile(
              mode: mode,
              onTap: () => _launchMode(context, mode),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.mode, required this.onTap});

  final RandomTestMode mode;
  final VoidCallback onTap;

  IconData get _icon => switch (mode) {
        RandomTestMode.classic => Icons.shuffle_rounded,
        RandomTestMode.practiced => Icons.check_circle_outline_rounded,
        RandomTestMode.refresh => Icons.schedule_rounded,
        RandomTestMode.mostErrors => Icons.error_outline_rounded,
        RandomTestMode.mixed => Icons.layers_rounded,
        RandomTestMode.reinforcement => Icons.fitness_center_rounded,
        RandomTestMode.markedReview => Icons.bookmark_rounded,
      };

  Color get _color => switch (mode) {
        RandomTestMode.classic => AppTheme.accentPurple,
        RandomTestMode.practiced => AppTheme.primary,
        RandomTestMode.refresh => AppTheme.accentOrange,
        RandomTestMode.mostErrors => Colors.red.shade400,
        RandomTestMode.mixed => AppTheme.cardDark,
        RandomTestMode.reinforcement => Colors.deepOrange.shade400,
        RandomTestMode.markedReview => AppTheme.accentOrange,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, color: _color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.subtitle,
                      style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
