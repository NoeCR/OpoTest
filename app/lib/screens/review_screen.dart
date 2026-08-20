import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/app_database.dart';
import '../models/review_entry.dart';
import '../navigation/app_navigation.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_decorations.dart';
import 'marked_question_study_screen.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  List<ReviewEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<AppState>().activeUser;
    if (user == null) return;

    final db = context.read<AppDatabase>();
    final marked = await db.markedQuestionsForUser(user.id);
    final entries = <ReviewEntry>[];

    for (final item in marked) {
      final test = await db.getTest(item.testId);
      if (test == null) continue;
      if (item.questionIndex < 0 || item.questionIndex >= test.questions.length) continue;
      entries.add(
        ReviewEntry(
          testId: item.testId,
          testName: test.name,
          questionIndex: item.questionIndex,
          question: test.questions[item.questionIndex],
          markedAt: item.markedAt,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _entries = entries;
        _loading = false;
      });
    }
  }

  Future<void> _openStudy(int index) async {
    await context.pushPage(
      MarkedQuestionStudyScreen(entries: _entries, initialIndex: index),
    );
    await _load();
  }

  Future<void> _removeEntry(ReviewEntry entry) async {
    final user = context.read<AppState>().activeUser!;
    await context.read<AppDatabase>().toggleMarkedQuestion(
          userId: user.id,
          testId: entry.testId,
          questionIndex: entry.questionIndex,
        );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      appBar: AppBar(
        title: const Text('Revisión'),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border_rounded, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'Sin preguntas marcadas',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Durante un test, pulsa el icono de marcador en una pregunta para añadirla aquí.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openStudy(index),
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          decoration: AppDecorations.card(),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentOrange.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.bookmark_rounded,
                                    color: AppTheme.accentOrange,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.testName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Pregunta ${entry.question.order}',
                                        style: TextStyle(
                                          color: AppTheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        entry.question.text,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14, height: 1.35),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Quitar de revisión',
                                  onPressed: () => _removeEntry(entry),
                                  icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
