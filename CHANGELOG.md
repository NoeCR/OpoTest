# Changelog

Todas las mejoras relevantes del proyecto se documentan en este archivo.

Este formato sigue una estructura inspirada en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y [SemVer](https://semver.org/lang/es/).

## [Unreleased]

---

## [1.2.0] - 2026-08-20

### Added
- Tests propios: crear, editar y eliminar tests manuales por ley.
- Hub en Home y editor con preguntas, respuestas y notas aclaratorias.
- Los tests propios aparecen en la pestaña «Preguntas propias» de cada ley.
- Arquitectura desacoplada (`domain`, `data`, `application`, `presentation`) con tests unitarios.

### Changed
- El test aleatorio excluye tests propios.

---

## [1.0.2] - 2026-08-18

### Changed
- Lista de Legislación con tarjetas unificadas: título, subtítulo, badge de progreso neutro y barra de avance con color.
- Oculta leyes y títulos sin tests en el temario importado.

### Fixed
- Tests a nivel de ley inaccesibles cuando no hay tests en títulos o capítulos (p. ej. RD364/1995).
- Lectura de índices `qByLaw` legacy con `mainLevel` como lista directa.

---

### Changed
- Opciones de respuesta sin prefijos A/B/C/D; la selección se indica con el borde.
- Cabecera de Perfil sin avatar superpuesto que se cortaba.
- Desplazamiento lateral entre preguntas durante un test activo.
- Subtítulos descriptivos en la jerarquía del temario (estilo Testea).
- Lista de títulos muestra solo bloques con tests; navegación directa a tests cuando los capítulos no tienen tests propios.

### Fixed
- Tests inaccesibles en leyes con capítulos estructurales pero tests a nivel de título (p. ej. LO3/1981).

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

