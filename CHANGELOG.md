# Changelog

Todas las mejoras relevantes del proyecto se documentan en este archivo.

Este formato sigue una estructura inspirada en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y [SemVer](https://semver.org/lang/es/).

## [Unreleased]

### Added
- Estrategia de importación no destructiva para tests oficiales, preservando tests personalizados (`source=custom`).
- Nueva pestaña de contenido: **Preguntas propias**.
- Tests unitarios para utilidades de jerarquía/progreso (`test/qmap_test.dart`).

### Changed
- UI de tarjetas con mejor contraste en el bloque inferior.
- Recuperación de métricas visuales en tarjetas de test (nota media y mejor nota).
- Pantalla de resultados ajustada para evitar solapes en cabecera.
- Render de notas aclaratorias mejorado para resaltar contenido relevante.

### Fixed
- Correcciones de recarga de progreso al volver de sesiones/test.
- Ajustes de responsive para reducir riesgo de overflow en portrait/landscape.

---

## [1.0.0] - 2026-08-18

### Added
- Base funcional de la app offline de tests de oposiciones.
- Persistencia SQLite para usuarios, intentos y estadísticas.
- Importación de leyes, títulos y tests desde contenido local.
- Flujo principal de práctica:
  - selección por legislación/temario,
  - ejecución de tests,
  - resultados y revisión.
- Exportación de datos de temario y scripts de soporte para emulador Android.

### Notes
- Versión inicial publicada del repositorio `OpoTest`.

