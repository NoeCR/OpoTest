import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AnswerGridCell extends StatelessWidget {
  const AnswerGridCell({
    super.key,
    required this.order,
    required this.state,
    required this.onTap,
  });

  final int order;
  final AnswerCellState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = switch (state) {
      AnswerCellState.correct => Colors.green.shade400,
      AnswerCellState.incorrect => Colors.red.shade400,
      AnswerCellState.unanswered => Colors.grey.shade400,
      AnswerCellState.current => AppTheme.primary,
    };
    final fg = state == AnswerCellState.current ? Colors.white : Colors.white;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Text(
            '$order',
            style: TextStyle(color: fg, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

enum AnswerCellState { correct, incorrect, unanswered, current }
