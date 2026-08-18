import 'package:flutter/material.dart';

import '../models/question.dart';
import '../navigation/app_navigation.dart';
import '../services/test_scoring.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_grid.dart';
import '../widgets/app_decorations.dart';
import '../widgets/score_stars.dart';
import 'test_session_screen.dart';

class TestResultScreen extends StatelessWidget {
  const TestResultScreen({
    super.key,
    required this.test,
    required this.answers,
    required this.result,
    required this.durationSeconds,
  });

  final TestDefinition test;
  final Map<int, int> answers;
  final Result result;
  final int durationSeconds;

  String _time(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  String _scoreLabel(Result result) {
    final net = result.netScore == result.netScore.roundToDouble()
        ? result.netScore.round().toString()
        : result.netScore.toString();
    return '$net · ${result.percentScore.round()}%';
  }

  AnswerCellState _cellState(Question q, int? a) {
    if (a == null || a == 0) return AnswerCellState.unanswered;
    return a == q.solution ? AnswerCellState.correct : AnswerCellState.incorrect;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientHeader(
            title: 'Resultados',
            subtitle: test.name,
            gradient: AppDecorations.darkHeaderGradient,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Container(
                  decoration: AppDecorations.card(),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    children: [
                      const Text(
                        'Nota neta',
                        style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _scoreLabel(result),
                        style: const TextStyle(
                          color: AppTheme.cardDark,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ScoreStars(percent: result.percentScore, size: 22),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'Correctas',
                              value: '${result.correct}',
                              color: const Color(0xFF2EAD5B),
                            ),
                          ),
                          Expanded(
                            child: _StatTile(
                              label: 'Incorrectas',
                              value: '${result.incorrect}',
                              color: AppTheme.primary,
                            ),
                          ),
                          Expanded(
                            child: _StatTile(
                              label: 'Sin responder',
                              value: '${result.unanswered}',
                              color: const Color(0xFFE6A817),
                            ),
                          ),
                          Expanded(
                            child: _StatTile(
                              label: 'Tiempo',
                              value: _time(durationSeconds),
                              color: AppTheme.cardDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Text(
                      'Revisión de respuestas',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    _LegendDot(color: Colors.green.shade400, label: 'OK'),
                    const SizedBox(width: 8),
                    _LegendDot(color: Colors.red.shade400, label: 'Fail'),
                    const SizedBox(width: 8),
                    _LegendDot(color: Colors.grey.shade400, label: '—'),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: test.questions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, i) {
                    final q = test.questions[i];
                    final a = answers[i];
                    return AnswerGridCell(
                      order: q.order,
                      state: _cellState(q, a),
                      onTap: () => context.pushPage(
                        TestSessionScreen(
                          test: test,
                          errorFormat: 100,
                          durationMinutes: 0,
                          examSimulation: false,
                          reviewMode: true,
                          initialAnswers: answers,
                          initialIndex: i,
                          initialElapsed: durationSeconds,
                        ),
                        transition: AppTransition.slideUp,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}
