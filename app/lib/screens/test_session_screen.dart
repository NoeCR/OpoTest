import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/local_user.dart';
import '../models/question.dart';
import '../services/test_scoring.dart';
import '../features/progress_sync/application/progress_sync_service.dart';
import '../navigation/app_navigation.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_grid.dart';
import '../widgets/clarification_sheet.dart';
import 'test_result_screen.dart';

class TestSessionScreen extends StatefulWidget {
  const TestSessionScreen({
    super.key,
    required this.test,
    required this.errorFormat,
    required this.durationMinutes,
    required this.examSimulation,
    this.reviewMode = false,
    this.initialAnswers = const {},
    this.initialIndex = 0,
    this.initialElapsed = 0,
  });

  final TestDefinition test;
  final int errorFormat;
  final int durationMinutes;
  final bool examSimulation;
  final bool reviewMode;
  final Map<int, int> initialAnswers;
  final int initialIndex;
  final int initialElapsed;

  @override
  State<TestSessionScreen> createState() => _TestSessionScreenState();
}

class _TestSessionScreenState extends State<TestSessionScreen> {
  late int currentIndex;
  late Map<int, int> answers;
  late int elapsed;
  late PageController _pageController;
  Timer? _timer;
  bool _advancing = false;
  Set<int> _markedIndices = {};
  final Map<int, ScrollController> _scrollControllers = {};

  bool get _useSwipeNavigation {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get _showQuestionNavButtons => widget.reviewMode || !_useSwipeNavigation;

  ScrollController _scrollControllerFor(int index) {
    return _scrollControllers.putIfAbsent(index, ScrollController.new);
  }

  bool get _hasTimeLimit => !widget.reviewMode && widget.durationMinutes > 0;
  int get _timeLimitSeconds => widget.durationMinutes * 60;
  int get _remainingSeconds =>
      _hasTimeLimit ? (_timeLimitSeconds - elapsed).clamp(0, _timeLimitSeconds) : 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    answers = Map.from(widget.initialAnswers);
    elapsed = widget.initialElapsed;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadMarkedQuestions();
    if (!widget.reviewMode) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => elapsed++);
        if (_hasTimeLimit && elapsed >= _timeLimitSeconds) {
          _finish(force: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get showClarification => widget.reviewMode || !widget.examSimulation;

  bool get _hasAnsweredQuestions => answers.values.any((v) => v > 0);

  int get _answeredCount => answers.values.where((v) => v > 0).length;

  Future<void> _loadMarkedQuestions() async {
    final user = context.read<AppState>().activeUser;
    if (user == null) return;
    final marked = await context.read<AppDatabase>().markedQuestionIndices(
          user.id,
          widget.test.id,
        );
    if (mounted) setState(() => _markedIndices = marked);
  }

  Future<void> _toggleMarked(int index) async {
    final user = context.read<AppState>().activeUser;
    if (user == null) return;
    final marked = await context.read<AppDatabase>().toggleMarkedQuestion(
          userId: user.id,
          testId: widget.test.id,
          questionIndex: index,
        );
    if (mounted) {
      setState(() {
        if (marked) {
          _markedIndices.add(index);
        } else {
          _markedIndices.remove(index);
        }
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() => currentIndex = index);
    final controller = _scrollControllers[index];
    if (controller?.hasClients ?? false) {
      controller!.jumpTo(0);
    }
  }

  void _goToQuestion(int index, {bool animate = true}) {
    if (index < 0 || index >= widget.test.questions.length) return;
    setState(() => currentIndex = index);
    if (_pageController.hasClients) {
      if (animate) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      } else {
        _pageController.jumpToPage(index);
      }
    }
  }

  void _select(int option) {
    if (widget.reviewMode || _advancing) return;

    final index = currentIndex;
    final isLast = index >= widget.test.questions.length - 1;
    setState(() => answers[index] = option);

    _advancing = true;
    final delay = widget.examSimulation ? Duration.zero : const Duration(milliseconds: 450);
    Future.delayed(delay, () async {
      if (!mounted) return;
      _advancing = false;
      if (isLast) {
        await _confirmFinish();
      } else {
        _goToQuestion(index + 1);
      }
    });
  }

  Future<void> _confirmFinish() async {
    if (widget.reviewMode) {
      await _finish();
      return;
    }

    final unanswered = widget.test.questions.length - _answeredCount;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(unanswered == widget.test.questions.length ? 'Salir del test' : 'Finalizar test'),
        content: Text(
          unanswered == widget.test.questions.length
              ? 'No has respondido ninguna pregunta. El intento no se guardará.'
              : unanswered > 0
                  ? 'Quedan $unanswered preguntas sin responder. ¿Quieres finalizar y ver los resultados?'
                  : '¿Quieres finalizar y ver los resultados?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Continuar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(unanswered == widget.test.questions.length ? 'Salir' : 'Finalizar'),
          ),
        ],
      ),
    );

    if (proceed == true && mounted) await _finish(force: false);
  }

  Future<void> _finish({bool force = false}) async {
    _timer?.cancel();
    if (!widget.reviewMode) {
      if (!_hasAnsweredQuestions) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test descartado: no se guardan intentos sin respuestas.')),
        );
        return;
      }

      final result = TestScoring.score(
        questions: widget.test.questions,
        answers: answers,
        errorFormat: widget.errorFormat,
      );
      final user = context.read<AppState>().activeUser!;
      final attempt = TestAttempt(
        id: const Uuid().v4(),
        userId: user.id,
        testId: widget.test.id,
        testName: widget.test.name,
        finishedAt: DateTime.now(),
        durationSeconds: elapsed,
        netScore: result.netScore,
        percentScore: result.percentScore,
        answers: answers,
        examSimulation: widget.examSimulation,
        errorFormat: widget.errorFormat,
      );
      await context.read<AppDatabase>().saveAttempt(attempt);
      if (!mounted) return;
      context.read<AppState>().notifyProgressChanged();
      unawaited(context.read<ProgressSyncService>().syncIfSignedIn());
      context.pushReplacementPage(
        TestResultScreen(
          test: widget.test,
          answers: answers,
          result: result,
          durationSeconds: elapsed,
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildQuestionNavigationRow(int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton.icon(
          onPressed: index > 0 ? () => _goToQuestion(index - 1) : null,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Anterior'),
        ),
        OutlinedButton.icon(
          onPressed: index < widget.test.questions.length - 1
              ? () => _goToQuestion(index + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
          label: const Text('Siguiente'),
        ),
      ],
    );
  }

  Widget _buildQuestionPage(int index) {
    final q = widget.test.questions[index];
    final selected = answers[index];

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: _scrollControllerFor(index),
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '${q.order}. ${q.text}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: _markedIndices.contains(index)
                                  ? 'Quitar de revisión'
                                  : 'Marcar para revisión',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              onPressed: () => _toggleMarked(index),
                              icon: Icon(
                                _markedIndices.contains(index)
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_outline_rounded,
                                color: _markedIndices.contains(index)
                                    ? AppTheme.accentOrange
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        if (showClarification && q.clarificationHtml.isNotEmpty)
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
                                builder: (_) => ClarificationSheet(html: q.clarificationHtml),
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
                for (var i = 0; i < q.answers.length; i++)
                  _AnswerTile(
                    text: q.answers[i],
                    selected: selected == i + 1,
                    state: _answerState(q, i + 1, selected),
                    onTap: () => _select(i + 1),
                  ),
                if (_showQuestionNavButtons) ...[
                  const SizedBox(height: 8),
                  _buildQuestionNavigationRow(index),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _timerWidget() {
    if (_hasTimeLimit) {
      final urgent = _remainingSeconds <= 60;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: urgent ? Colors.red.shade200 : Colors.white70),
          const SizedBox(width: 4),
          Text(
            _formatTime(_remainingSeconds),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: urgent ? Colors.red.shade100 : Colors.white,
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.schedule, size: 16, color: Colors.white70),
        const SizedBox(width: 4),
        Text(_formatTime(elapsed), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed = _answeredCount;
    final progress = (currentIndex + 1) / widget.test.questions.length;

    return PopScope(
      canPop: widget.reviewMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !widget.reviewMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Finaliza el test para ver los resultados.')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.pageBlue,
        appBar: AppBar(
          automaticallyImplyLeading: widget.reviewMode,
          title: Text(widget.test.name, maxLines: 1, overflow: TextOverflow.ellipsis),
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
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(child: _timerWidget()),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$completed/${widget.test.questions.length}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
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
                  if (widget.reviewMode) ...[
                    TextButton(onPressed: _showIndex, child: const Text('ÍNDICE')),
                    Text(
                      '${currentIndex + 1}/${widget.test.questions.length}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                  ] else
                    Expanded(
                      child: Text(
                        _hasTimeLimit
                            ? 'Tiempo restante: ${_formatTime(_remainingSeconds)}'
                            : 'Tiempo: ${_formatTime(elapsed)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _hasTimeLimit && _remainingSeconds <= 60
                              ? Colors.red.shade700
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: widget.reviewMode ? _finish : _confirmFinish,
                    child: Text(widget.reviewMode ? 'CERRAR' : 'FINALIZAR'),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white,
                  color: AppTheme.primary,
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: _useSwipeNavigation
                    ? const PageScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: widget.test.questions.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (_, index) => _buildQuestionPage(index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _AnswerVisual _answerState(Question q, int option, int? selected) {
    if (widget.reviewMode || (!widget.examSimulation && selected != null && selected != 0)) {
      if (option == q.solution) return _AnswerVisual.correct;
      if (option == selected) return _AnswerVisual.incorrect;
    } else if (!widget.examSimulation && selected == option) {
      if (option == q.solution) return _AnswerVisual.correct;
      return _AnswerVisual.incorrect;
    }
    return _AnswerVisual.normal;
  }

  void _showIndex() {
    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Índice de preguntas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: widget.test.questions.length,
                  itemBuilder: (_, i) {
                    final q = widget.test.questions[i];
                    final a = answers[i];
                    AnswerCellState state;
                    if (i == currentIndex && (a == null || a == 0)) {
                      state = AnswerCellState.current;
                    } else if (a == null || a == 0) {
                      state = AnswerCellState.unanswered;
                    } else {
                      state = a == q.solution ? AnswerCellState.correct : AnswerCellState.incorrect;
                    }
                    return AnswerGridCell(
                      order: q.order,
                      state: state,
                      onTap: () {
                        _goToQuestion(i);
                        Navigator.pop(c);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

enum _AnswerVisual { normal, correct, incorrect }

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.text,
    required this.selected,
    required this.state,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final _AnswerVisual state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color? border;
    Color? cardBg;

    if (state == _AnswerVisual.correct) {
      border = Colors.green.shade400;
      cardBg = Colors.green.shade50;
    } else if (state == _AnswerVisual.incorrect) {
      border = Colors.red.shade400;
      cardBg = Colors.red.shade50;
    } else if (selected) {
      border = AppTheme.primary;
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
