import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/app_database.dart';
import '../models/local_user.dart';
import '../navigation/app_navigation.dart';
import '../services/test_scoring.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_decorations.dart';
import '../widgets/score_stars.dart';
import 'test_result_screen.dart';

class TestHistoryScreen extends StatefulWidget {
  const TestHistoryScreen({super.key});

  @override
  State<TestHistoryScreen> createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  List<TestAttempt> _attempts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AppState>().activeUser?.id;
    if (userId == null) return;
    final attempts = await context.read<AppDatabase>().attemptsForUserModel(userId);
    if (mounted) {
      setState(() {
        _attempts = attempts;
        _loading = false;
      });
    }
  }

  Future<void> _openAttempt(TestAttempt attempt) async {
    final db = context.read<AppDatabase>();
    final test = await db.getTest(attempt.testId);
    if (!mounted) return;
    if (test == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El test ya no está disponible en el temario.')),
      );
      return;
    }

    final result = TestScoring.score(
      questions: test.questions,
      answers: attempt.answers,
      errorFormat: attempt.errorFormat,
    );

    await context.pushPage(
      TestResultScreen(
        test: test,
        answers: attempt.answers,
        result: result,
        durationSeconds: attempt.durationSeconds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.pageBlue,
        appBar: AppBar(title: const Text('Historial')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_attempts.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.pageBlue,
        body: Column(
          children: [
            const GradientHeader(title: 'Historial', subtitle: 'Tests realizados'),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'Sin tests completados',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cuando finalices un test, aparecerá aquí con su nota y la fecha.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final percents = _attempts.map((a) => a.percentScore).toList();
    final avg = percents.reduce((a, b) => a + b) / percents.length;
    final best = percents.reduce((a, b) => a > b ? a : b);
    final groups = _groupAttempts(_attempts);

    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientHeader(
            title: 'Historial',
            subtitle: '${_attempts.length} tests realizados',
            trailing: ScoreStars(percent: avg, size: 16),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(child: _SummaryPill(label: 'Tests', value: '${_attempts.length}')),
                const SizedBox(width: 10),
                Expanded(child: _SummaryPill(label: 'Media', value: '${avg.round()}%')),
                const SizedBox(width: 10),
                Expanded(child: _SummaryPill(label: 'Mejor', value: '${best.round()}%')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Text(
                        group.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    for (final attempt in group.attempts) ...[
                      _HistoryTile(
                        attempt: attempt,
                        onTap: () => _openAttempt(attempt),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (index < groups.length - 1) const SizedBox(height: 6),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryGroup {
  const _HistoryGroup({required this.label, required this.attempts});

  final String label;
  final List<TestAttempt> attempts;
}

List<_HistoryGroup> _groupAttempts(List<TestAttempt> attempts) {
  final map = <String, List<TestAttempt>>{};
  for (final attempt in attempts) {
    final label = _dateGroupLabel(attempt.finishedAt);
    map.putIfAbsent(label, () => []).add(attempt);
  }
  return map.entries.map((e) => _HistoryGroup(label: e.key, attempts: e.value)).toList();
}

String _dateGroupLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;

  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  if (diff < 7) return 'Esta semana';
  if (diff < 14) return 'Semana pasada';
  return _monthYearLabel(date);
}

const _monthNames = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

String _monthYearLabel(DateTime date) =>
    '${_monthNames[date.month - 1]} ${date.year}';

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.attempt, required this.onTap});

  final TestAttempt attempt;
  final VoidCallback onTap;

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} · '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final grade = TestScoring.gradeOnTen(
      netScore: attempt.netScore,
      percentScore: attempt.percentScore,
    );
    final gradeLabel = TestScoring.formatGrade(grade);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${attempt.percentScore.round()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attempt.testName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(attempt.finishedAt),
                      style: const TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    ScoreStars(percent: attempt.percentScore, size: 13),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Nota $gradeLabel/10',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cardDark),
                  ),
                  Text(
                    _formatDuration(attempt.durationSeconds),
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: AppDecorations.card(),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45)),
        ],
      ),
    );
  }
}
