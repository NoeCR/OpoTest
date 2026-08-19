class TestStats {
  const TestStats({
    this.avgPercent,
    this.bestPercent,
    this.lastPercent,
    this.attempts = 0,
  });

  final double? avgPercent;
  final double? bestPercent;
  final double? lastPercent;
  final int attempts;

  bool get hasAttempts => attempts > 0;
  bool get lastPerfect => lastPercent != null && lastPercent! >= 100;

  String get avgLabel => avgPercent != null ? '${avgPercent!.round()}%' : '--';
  String get bestLabel => bestPercent != null ? '${bestPercent!.round()}%' : '--';
  String get lastLabel => lastPercent != null ? '${lastPercent!.round()}%' : '--';

  /// Porcentaje principal para mostrar en la tarjeta (último intento, o mejor si no hay último).
  double? get displayPercent => lastPercent ?? bestPercent;
}
