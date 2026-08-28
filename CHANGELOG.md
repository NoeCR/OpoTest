# Changelog

Todas las mejoras relevantes del proyecto se documentan en este archivo.

Este formato sigue una estructura inspirada en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y [SemVer](https://semver.org/lang/es/).

## [Unreleased]

---

## [1.17.0] - 2026-08-28

### Added
- En Inicio y en Test aleatorio hay un Simulacro: mezcla las pruebas reales de convocatoria que hayas importado (`officialpaper`), no las preguntas oficiales recortadas por ley. N preguntas (50/100/150), tiempo fijo y sin corrección hasta el final. Los fallos restan 1. No entra en el informe de fallos ni en el mapa de puntos débiles. Antes de empezar se listan las pruebas agrupadas por administración y año para incluir o excluir las que interesen.

---

## [1.16.0] - 2026-08-28

### Added
- En Inicio, la tarjeta Repaso (entre Revisión y Configuración) muestra un mapa de puntos débiles: leyes y títulos con media, último % e intentos, lo más flojo arriba. Tocar una abre esa parte del temario.

---

## [1.15.0] - 2026-08-28

### Added
- Se puede buscar en el temario (leyes, títulos, tests y enunciados) desde Inicio y Legislación.

---

## [1.14.1] - 2026-08-28

### Changed
- La tarjeta «Hoy» muestra cada propuesta como una opción aparte (subtarjeta), no como texto suelto.

### Fixed
- El foco del día deja de proponer «Repasar marcas» el mismo día después de terminar ese test; propone lo siguiente (fallos, test flojo o azar). Las marcas se quedan para otro día.
- Un acierto al repasar fallos saca esa pregunta de la lista de fallos (foco del día y test de refuerzo). Si se vuelve a fallar, reaparece.

---

## [1.14.0] - 2026-08-27

### Added
- En Inicio aparece «Hoy»: una propuesta para practicar (marcas recientes, fallos de 7 días, el test más flojo o un test al azar), usando los modos que ya existen.

---

## [1.13.0] - 2026-08-27

### Added
- Se puede pausar un test a medias y continuarlo más tarde desde Inicio. El intento no se guarda en el historial hasta que se finaliza. Sirve también para tests aleatorios.

---

## [1.12.0] - 2026-08-27

### Added
- En Configuración se puede programar un recordatorio del informe de fallos (ninguno, diario o semanal). Al abrir la app, si toca y hay fallos, aparece un aviso para generarlo.

---

## [1.11.0] - 2026-08-27

### Added
- En Legislación se puede ordenar las secciones de forma personalizada, arrastrándolas, y bloquear el orden con un candado para hacer scroll sin moverlas.

---

## [1.10.0] - 2026-08-26

### Added
- En Test aleatorio se puede practicar solo con tests propios (los creados por el usuario).

---

## [1.9.0] - 2026-08-25

### Added
- En Inicio se puede exportar un informe HTML de preguntas falladas (respuesta, correcta, aclaración y ley) filtrable por periodo, y abrirlo en el navegador. Al imprimir o guardar, el nombre incluye perfil y fecha.

---

## [1.8.1] - 2026-08-25

### Fixed
- Tras importar el temario por JSON, Inicio reconoce el contenido y habilita el test aleatorio.

---

## [1.8.0] - 2026-08-25

### Added
- En la pantalla de cuentas se puede importar un perfil exportado (Drive, correo, etc.) sin crear una cuenta nueva.

### Changed
- Identificadores de paquete y binario a OpoTest (`com.opotest.app`). En Android es una instalación distinta: exporta el progreso antes de reinstalar.
- Al exportar progreso o contenido, se abre el menú de compartir del sistema (Drive, correo, etc.) en lugar de dejar el JSON solo en una carpeta interna.
- El JSON exportado se nombra `OpoTest · {perfil}_{yyyy/MM/dd : HH:mm:ss}` al compartirlo (Drive, correo, etc.).

---

## [1.7.3] - 2026-08-25

### Fixed
- El contador de tests realizados en Legislación se actualiza al volver atrás tras completar un test, sin salir a Inicio.

---

## [1.7.2] - 2026-08-23

### Changed
- El pie de Configuración muestra la versión y el número de build de la app.

---

## [1.7.1] - 2026-08-22

### Fixed
- Al añadir una pregunta en el editor de tests propios, la vista hace scroll automático hasta la nueva pregunta.

---

## [1.7.0] - 2026-08-22

### Added
- Modos **Test de refuerzo** (preguntas falladas en intentos recientes) y **Test de repaso** (preguntas marcadas).
- Tests unitarios del hub de tests aleatorios (estrategias, builder sintético y servicio).

### Changed
- Refactor del hub de tests aleatorios con patrón **Strategy** (registry + una estrategia por modo).
- `RandomTestPick` y constantes extraídos a capa de dominio; builder de tests sintéticos reutilizable.

---

## [1.6.5] - 2026-08-22

### Added
- Botones Anterior/Siguiente en tests en escritorio (Windows/macOS/Linux/web).
- Diálogo automático al responder la última pregunta de un test.

### Changed
- Nota normalizada de 0 a 10, independiente del número de preguntas del test.

### Fixed
- Scroll al volver a preguntas anteriores en móvil durante un test.
- Los intentos sin ninguna respuesta ya no se guardan ni aparecen en historial o medias.

---

## [1.6.4] - 2026-08-20

### Added
- Script `export-content-backup.ps1` para generar JSON de contenido importable (APK + JSON sin ADB).
- Guía de distribución actualizada en `releases/README.md`.

---

## [1.6.3] - 2026-08-20

### Fixed
- Permiso `INTERNET` en builds release de Android (comprobar actualizaciones).
- Script `push-data-android.ps1` compatible con APK release (sin `run-as`).
- Mensajes de error comprensibles en importación, sync, backup y arranque.

---

## [1.6.2] - 2026-08-20

### Changed
- Nuevo icono de aplicación OpoTest en Android, iOS, Windows, macOS y web.

---

## [1.6.1] - 2026-08-20

### Added
- Editor de notas aclaratorias en tests propios con negrita, cursiva y vista previa HTML.

---

## [1.6.0] - 2026-08-20

### Added
- Hub de **Test aleatorio** con modos: al azar, temario practicado, refrescar olvidados, más fallos recientes y mixto multisección.
- Selección inteligente basada en historial de intentos (fechas, duración y errores).

---

## [1.5.0] - 2026-08-20

### Added
- Sección **Historial** con tests realizados, notas, fechas y duración agrupados por periodo.
- Detalle de cada intento con revisión completa de respuestas.

### Changed
- «Estadísticas» sustituida por Historial en Home y Perfil.

---

## [1.4.0] - 2026-08-20

### Added
- Marcar preguntas para revisión durante un test (icono de marcador en cada pregunta).
- Sección **Revisión** en Home con listado y modo estudio (respuestas, nota aclaratoria, navegación).
- Persistencia de marcas por usuario e inclusión en backup de progreso (v3).

---

## [1.3.0] - 2026-08-20

### Added
- Copias de seguridad de contenido y progreso (export/import JSON) en Configuración.
- Import de progreso con opción fusionar o reemplazar intentos del perfil.
- Secciones propias «Otros» al crear tests custom; aparecen en Legislación.

### Changed
- Rebrand a OpoTest en exports, logs e identidad visible (compatibilidad con backups `testea_local`).

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

