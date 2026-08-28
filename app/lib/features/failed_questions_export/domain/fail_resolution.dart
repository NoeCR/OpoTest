/// Decide si una pregunta sigue siendo un fallo actual.
/// Los intentos deben recorrerse de más reciente a más antiguo.
class FailResolution {
  FailResolution(this.recoveredAtByKey);

  final Map<String, DateTime> recoveredAtByKey;
  final Set<String> _seen = {};

  static String key(String testId, int questionIndex) => '$testId:$questionIndex';

  /// Primera respuesta vista para esa pregunta. `true` si aún cuenta como fallo.
  bool isCurrentFail({
    required String testId,
    required int questionIndex,
    required bool correct,
    required DateTime at,
  }) {
    final k = key(testId, questionIndex);
    if (!_seen.add(k)) return false;
    if (correct) return false;
    final recoveredAt = recoveredAtByKey[k];
    if (recoveredAt != null && !recoveredAt.isBefore(at)) return false;
    return true;
  }
}
