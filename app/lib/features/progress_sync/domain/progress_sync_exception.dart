class ProgressSyncException implements Exception {
  ProgressSyncException(
    this.message, {
    this.cancelled = false,
    this.notConfigured = false,
  });

  final String message;
  final bool cancelled;
  final bool notConfigured;

  @override
  String toString() => message;
}
