/// Formatea la etiqueta de versión que se muestra en Configuración.
String formatAppVersionLabel({
  required String version,
  required String buildNumber,
}) {
  final trimmedVersion = version.trim();
  final trimmedBuild = buildNumber.trim();
  if (trimmedVersion.isEmpty) return 'Versión desconocida';
  if (trimmedBuild.isEmpty) return 'Versión $trimmedVersion';
  return 'Versión $trimmedVersion ($trimmedBuild)';
}
