import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/app_database.dart';
import '../models/question.dart';
import '../models/review_entry.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/clarification_sheet.dart';

class MarkedQuestionStudyScreen extends StatefulWidget {
  const MarkedQuestionStudyScreen({
    super.key,
    required this.entries,
    required this.initialIndex,
  });

  final List<ReviewEntry> entries;
  final int initialIndex;

  @override
  State<MarkedQuestionStudyScreen> createState() => _MarkedQuestionStudyScreenState();
}

class _MarkedQuestionStudyScreenState extends State<MarkedQuestionStudyScreen> {
  late int _index;
  late List<ReviewEntry> _entries;
  int? _selectedOption;

  ReviewEntry get _entry => _entries[_index];
  Question get _question => _entry.question;

  @override
  void initState() {
    super.initState();
    _entries = List<ReviewEntry>.from(widget.entries);
    _index = widget.initialIndex.clamp(0, _entries.length - 1);
  }

  Future<void> _toggleMark() async {
    final user = context.read<AppState>().activeUser!;
    await context.read<AppDatabase>().toggleMarkedQuestion(
          userId: user.id,
          testId: _entry.testId,
          questionIndex: _entry.questionIndex,
        );
    if (!mounted) return;

    setState(() {
      _entries.removeAt(_index);
      if (_index >= _entries.length && _entries.isNotEmpty) {
        _index = _entries.length - 1;
      }
      _selectedOption = null;
    });
    if (_entries.isEmpty && mounted) Navigator.pop(context);
  }

  void _goTo(int delta) {
    setState(() {
      _index = (_index + delta).clamp(0, _entries.length - 1);
      _selectedOption = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Estudio')),
        body: const Center(child: Text('No quedan preguntas marcadas.')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      appBar: AppBar(
        title: Text(_entry.testName, maxLines: 1, overflow: TextOverflow.ellipsis),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary.withValues(alpha: 0.9), AppTheme.cardDark.withValues(alpha: 0.95)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Quitar de revisión',
            onPressed: _toggleMark,
            icon: const Icon(Icons.bookmark_rounded),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        elevation: 8,
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _index > 0 ? () => _goTo(-1) : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Anterior'),
                ),
                const Spacer(),
                Text(
                  '${_index + 1}/${_entries.length}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _index < _entries.length - 1 ? () => _goTo(1) : null,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Siguiente'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_question.order}. ${_question.text}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.35),
                  ),
                  if (_question.clarificationHtml.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (_) => ClarificationSheet(html: _question.clarificationHtml),
                        ),
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('Nota aclaratoria'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _question.answers.length; i++)
            _StudyAnswerTile(
              text: _question.answers[i],
              state: _answerState(i + 1),
              onTap: () => setState(() => _selectedOption = i + 1),
            ),
          if (_selectedOption == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Pulsa una respuesta para comprobarla.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  _StudyAnswerVisual _answerState(int option) {
    if (_selectedOption == null) return _StudyAnswerVisual.normal;
    if (option == _question.solution) return _StudyAnswerVisual.correct;
    if (option == _selectedOption) return _StudyAnswerVisual.incorrect;
    return _StudyAnswerVisual.normal;
  }
}

enum _StudyAnswerVisual { normal, correct, incorrect }

class _StudyAnswerTile extends StatelessWidget {
  const _StudyAnswerTile({
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String text;
  final _StudyAnswerVisual state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color? border;
    Color? cardBg;

    if (state == _StudyAnswerVisual.correct) {
      border = Colors.green.shade400;
      cardBg = Colors.green.shade50;
    } else if (state == _StudyAnswerVisual.incorrect) {
      border = Colors.red.shade400;
      cardBg = Colors.red.shade50;
    }

    return Card(
      color: cardBg,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border ?? Colors.transparent, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(text, style: const TextStyle(fontSize: 15, height: 1.35)),
        ),
      ),
    );
  }
}
