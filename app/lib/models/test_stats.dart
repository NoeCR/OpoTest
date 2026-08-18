class TestStats {
  const TestStats({
    this.avgPercent,
    this.bestPercent,
    this.attempts = 0,
  });

  final double? avgPercent;
  final double? bestPercent;
  final int attempts;

  String get avgLabel => avgPercent != null ? '${avgPercent!.round()}%' : '--';
  String get bestLabel => bestPercent != null ? '${bestPercent!.round()}%' : '--';
}
