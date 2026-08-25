enum FailedQuestionsPreset {
  sinceLastExport,
  lastDay,
  last7Days,
  custom,
}

class FailedQuestionsRange {
  const FailedQuestionsRange({
    required this.from,
    required this.to,
    required this.preset,
  });

  final DateTime from;
  final DateTime to;
  final FailedQuestionsPreset preset;

  factory FailedQuestionsRange.lastDay({DateTime? now}) {
    final n = now ?? DateTime.now();
    return FailedQuestionsRange(
      from: n.subtract(const Duration(days: 1)),
      to: n,
      preset: FailedQuestionsPreset.lastDay,
    );
  }

  factory FailedQuestionsRange.last7Days({DateTime? now}) {
    final n = now ?? DateTime.now();
    return FailedQuestionsRange(
      from: n.subtract(const Duration(days: 7)),
      to: n,
      preset: FailedQuestionsPreset.last7Days,
    );
  }

  factory FailedQuestionsRange.sinceLastExport({
    required DateTime lastExportAt,
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    return FailedQuestionsRange(
      from: lastExportAt,
      to: n,
      preset: FailedQuestionsPreset.sinceLastExport,
    );
  }

  factory FailedQuestionsRange.custom({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final from = DateTime(startDate.year, startDate.month, startDate.day);
    final to = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
    return FailedQuestionsRange(
      from: from,
      to: to.isBefore(from) ? from : to,
      preset: FailedQuestionsPreset.custom,
    );
  }

  bool contains(DateTime at) {
    return !at.isBefore(from) && !at.isAfter(to);
  }

  String get label {
    String two(int n) => n.toString().padLeft(2, '0');
    final localFrom = from.toLocal();
    final localTo = to.toLocal();
    final fromLabel =
        '${localFrom.year}-${two(localFrom.month)}-${two(localFrom.day)} ${two(localFrom.hour)}:${two(localFrom.minute)}';
    final toLabel =
        '${localTo.year}-${two(localTo.month)}-${two(localTo.day)} ${two(localTo.hour)}:${two(localTo.minute)}';
    return '$fromLabel — $toLabel';
  }
}
