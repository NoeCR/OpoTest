# Hoja de ruta funcional — OpoTest

Documento de trabajo para ir abordando funcionalidades **punto a punto**.  
Base: OpoTest **v1.13.0** (offline, SQLite, Flutter). Cada punto está pensado como **un release menor** (`1.x.0`), con tests y entrada en `CHANGELOG.md`.

## Cómo usar este documento

1. Coge **un solo punto** (el siguiente pendiente de la lista).
2. No mezcles dos puntos en el mismo commit/release salvo que uno sea prerequisito explícito.
3. Cuando esté hecho: marca la casilla, anota la versión y pasa al siguiente.
4. Si cambia el criterio, edita este archivo; no lo dejes desactualizado.

**Criterio general:** usar datos que ya existen (intentos, fallos, marcas, leyes), mantenerse offline y notarse en tablet, móvil y Windows.

**Fuera de alcance (no abrir ahora):** más modos de test aleatorio (ya hay ocho), IA para generar preguntas, comunidad o nube obligatoria.

---

## Estado de la app (punto de partida)

| Ya existe | Hueco |
|---|---|
| Temario local, SQLite, usuarios locales | — |
| 8 modos de test aleatorio + foco del día (v1.14.0) | — |
| Búsqueda en el temario (v1.15.0) | — |
| Informe HTML de fallos + recordatorio | No hay intervalo de repaso por pregunta |
| Marcas, refuerzo, historial | Perfil solo muestra nº de intentos y media |
| Pausar y continuar un test a medias (v1.13.0) | — |
| Tests propios CRUD + backup/compartir progreso | No se comparte un test propio suelto |
| Orden personalizado de leyes | No hay filtros (nunca hecho / completado) |

Archivos ancla:

- Sesión: `app/lib/screens/test_session_screen.dart`, `app/lib/services/test_launcher.dart`
- Inicio: `app/lib/screens/home_screen.dart`
- BD: `app/lib/database/app_database.dart` (versión **5**)
- Fallos: `app/lib/features/failed_questions_export/`
- Aleatorio: `app/lib/features/random_tests/`
- Tests propios: `app/lib/features/custom_tests/`
- Búsqueda: `app/lib/features/temario_search/`

---

## Fase 0 — Cerrar el uso diario

### 0.1 Continuar un test a medias

- **Prioridad:** P0 (primero)
- **Esfuerzo:** medio
- **Dependencias:** ninguna
- **Estado:** [x] Hecho en **v1.13.0**

**Qué es.** Poder salir a mitad de un test (llamada, cambio de app, cierre) y retomarlo con las mismas preguntas, respuestas, índice y tiempo.

**Por qué.** Hoy `TestSessionScreen` guarda el intento **solo al finalizar**. `PopScope` impide atrás y el estado vive en memoria. En tablet/móvil es el fallo que más rompe el hábito. Los tests aleatorios sintéticos (`mixed_random`, `reinforcement_random`, `review_random`) no se pueden relanzar por `testId`: hay que **serializar el `TestDefinition`**.

**Criterio de hecho.**

- Al responder, cambiar de pregunta o cada ~10 s de reloj se persiste la sesión del usuario activo.
- En Inicio, si hay sesión a medias: tarjeta «Continuar test» (nombre, pregunta X/Y, tiempo).
- Atrás / salir pregunta «Pausar» (guarda y cierra) o «Finalizar» (flujo actual).
- Al terminar o al descartar (cero respuestas), se borra la sesión.
- Un test nuevo pregunta si hay otra sesión a medias (reanudar / sustituir).
- Restaurar tras matar el proceso funciona igual en Android y Windows.

**Cómo llevarlo a cabo.**

1. **Modelo** `InProgressSession`: `userId`, `testId`, `testName`, `payloadJson` (snapshot del test), `answersJson`, `currentIndex`, `elapsedSeconds`, `errorFormat`, `durationMinutes`, `examSimulation`, `updatedAt`.
2. **Tabla SQLite** `in_progress_sessions` (PK `user_id`). Migración BD **3 → 4** en `app_database.dart` (`_onUpgrade`). Borrar al `deleteUserData`.
3. **Servicio** `InProgressSessionStore` (guardar / leer / borrar). Debounce al escribir.
4. **`TestSessionScreen`:** aceptar snapshot; autosave; `PopScope` con diálogo Pausar / Finalizar; al `_finish` borrar sesión.
5. **`TestLauncher`:** si hay sesión de otro test, confirmar; si es el mismo, reanudar con `initialAnswers` / `initialIndex` / `initialElapsed` (ya existen).
6. **`HomeScreen`:** cargar sesión en `_loadMeta`; tile o banner encima de la parrilla.
7. **Tests:** serializar/deserializar; «un usuario, una sesión»; no crear `attempts` al pausar.

**No hacer.** Convertir la pausa en un intento a medias en `attempts` (ensuciaría historial, informe de fallos y modos aleatorios).

---

### 0.2 Foco del día

- **Prioridad:** P0 (segundo)
- **Esfuerzo:** medio
- **Dependencias:** ninguna (mejora si existe 1.1 mapa de débiles)
- **Estado:** [x] Hecho en **v1.14.0**

**Qué es.** En Inicio, una propuesta concreta: «hoy haz esto», no ocho modos a elegir.

**Por qué.** Ya hay refuerzo, marcas, más fallos y recordatorio del informe. Falta el *qué* diario. El recordatorio cubre el *cuándo* exportar; esto cubre el *qué practicar*.

**Criterio de hecho.**

- Con temario e intentos: tarjeta en Inicio con 1 acción principal y hasta 2 secundarias.
- Tocar lanza el test o el modo ya existente (no un noveno modo aleatorio).
- Sin datos: copy útil («Haz un test de cualquier ley para empezar»), no error.
- Recalcula al volver de un test y al `resumed`.
- Si ya se terminó un test de repaso de marcas **hoy**, esas marcas no vuelven a proponerse el mismo día (sale la siguiente prioridad). Mañana sí, si siguen marcadas. Una marca nueva posterior al repaso sí cuenta.
- Un acierto al **repasar fallos** (o en otro test sintético con origen) saca esa pregunta de la lista de fallos; si se vuelve a fallar, reaparece.
- La tarjeta «Hoy» muestra cada propuesta como subtarjeta accionable (recomendada + alternativas).

**Cómo llevarlo a cabo.**

1. **Dominio** `DailyFocusService` que, para el usuario, calcule candidatos:
   - Preguntas marcadas → `RandomTestMode.markedReview`.
   - Fallos recientes → reutilizar `FailedQuestionsCollector` (p. ej. 7 días) → `reinforcement`.
   - Ley o test con peor `lastPercent` / más intentos flojos → `statsForTests` + `mostErrors` o el propio test.
   - Si no hay nada: `classic` o «Reintentar último».
2. **Prioridad fija y predecible** (marcas con tope de antigüedad → fallos → ley floja → azar). Documentarla en el servicio y en tests unitarios.
3. **UI:** una card encima de «Nuevo test» en `home_screen.dart` (título, razón en una línea, botón). No sustituir la parrilla.
4. **Tests** del orden de prioridad con fixtures de intentos/marcas.

**No hacer.** Gamificación (ligas, puntos). Un algoritmo opaco imposible de explicar en una línea.

---

### 0.3 Búsqueda en el temario

- **Prioridad:** P0 (tercero)
- **Esfuerzo:** medio
- **Dependencias:** ninguna
- **Estado:** [x] Hecho en **v1.15.0**

**Qué es.** Buscar por texto leyes, títulos, tests y (si rinde) enunciados de preguntas.

**Por qué.** El orden personalizado ya está. El cuello de botella es localizar «excedencia», «silencio administrativo», un test concreto.

**Criterio de hecho.**

- Acceso desde Inicio y/o Legislación (icono de lupa).
- Resultados agrupados: Leyes, Títulos, Tests. Opcional: Preguntas.
- Tocar navega a la pantalla que ya existe (`LawsScreen` / jerarquía / lista de tests / lanzar test).
- Funciona offline; vacío y «sin coincidencias» claros.
- Con ~el temario real, una búsqueda corta no congela la UI (isolate o índice).

**Cómo llevarlo a cabo.**

1. **v1 (suficiente):** `LIKE` / contains sobre `laws.name`, `titles.name`, `tests.name`. Pantalla `SearchScreen` o `SearchDelegate`.
2. **v1.1:** buscar en `payload` de tests (`text_es`) con límite (p. ej. 30 hits) y debounce 250 ms.
3. Si el temario crece y va lento: tabla FTS5 o índice al importar; no hace falta en el primer corte.
4. Navegación: ley → `HierarchyScreen`; título → tests de ese título; test → `TestLauncher.start`.
5. **Tests** de ranking (nombre exacto > prefijo > contiene) con SQLite de prueba.

**No hacer.** Búsqueda en servidor. Elasticsearch.

---

## Fase 1 — Entender y examinar

### 1.1 Mapa de puntos débiles

- **Prioridad:** P1
- **Esfuerzo:** medio
- **Dependencias:** ninguna; alimenta 0.2 y 1.3
- **Estado:** [ ] Pendiente

**Qué es.** En Perfil (o una pantalla «Progreso»), lista de leyes/títulos con media, último % e intentos. Lo flojo arriba.

**Por qué.** Perfil solo tiene intentos y media global. Sin desglose, el orden de leyes y el aleatorio se usan a ciegas.

**Criterio de hecho.** Lista ordenable; tocar una ley abre esa ley en Legislación; tests sintéticos fuera del agregado (como en el informe de fallos).

**Cómo llevarlo a cabo.**

1. Query: `attempts` ⨝ `tests.law_id` / `title_id`; ignorar IDs de `RandomTestConstants.isSyntheticAttemptTestId`.
2. Reutilizar `TestStats` (avg / last / attempts) a nivel ley y título.
3. UI en `profile_screen.dart` o `ProgressScreen`. Sin librería de gráficos en este punto.
4. Tests del agregado con intentos de varias leyes.

---

### 1.2 Simulacro a tamaño real

- **Prioridad:** P1
- **Esfuerzo:** medio
- **Dependencias:** 0.1 (pausa/continuar) muy recomendable
- **Estado:** [ ] Pendiente

**Qué es.** Un preset «Simulacro»: N preguntas (p. ej. 100), tiempo fijo, mezcla de leyes, sin corrección inmediata. No es el toggle actual de simulación (solo oculta la corrección).

**Criterio de hecho.** Desde Test aleatorio o Inicio; N y minutos configurables (guardados); al terminar, nota 0–10 con las reglas ya existentes de penalización.

**Cómo llevarlo a cabo.**

1. Extender `MixedRandomTestStrategy` (ahora `mixedQuestionCount = 15`) con `questionCount` y opcionalmente leyes incluidas.
2. Preset en `TestPreferences`: `simulacrumQuestions`, `simulacrumMinutes`, fuerza `examSimulation = true` al lanzar.
3. Tile «Simulacro» en `random_test_hub_screen.dart`.
4. Reutilizar `TestScoring` y resultado. El ID sintético debe seguir excluido del informe de fallos o documentar si se incluye.

**No hacer.** Un motor de examen distinto al de `TestSessionScreen`.

---

### 1.3 Repaso espaciado de fallos

- **Prioridad:** P1
- **Esfuerzo:** alto
- **Dependencias:** 0.2 ayuda; el collector y el recordatorio ya existen
- **Estado:** [ ] Pendiente

**Qué es.** Cada fallo tiene fecha de próximo repaso (p. ej. 1 / 3 / 7 / 16 días). El foco del día y/o el test de refuerzo priorizan lo que toca hoy.

**Criterio de hecho.** Tras un intento, los fallos programan el siguiente pase; un acierto en repaso alarga el intervalo; «hoy» solo saca preguntas vencidas (con un mínimo si no hay ninguna).

**Cómo llevarlo a cabo.**

1. Tabla `question_review_state` (`user_id`, `test_id`, `question_index`, `box`, `next_due`, `last_result`). BD **4 o 5**.
2. Al `saveAttempt`, actualizar cajas (Leitner simple, 5 cajas).
3. Estrategia o filtro sobre `ReinforcementRandomTestStrategy`: `next_due <= today`.
4. Enlazar con el recordatorio de fallos: el diálogo puede decir «tienes N para repasar» además de exportar.
5. Tests puros del algoritmo de cajas (sin UI).

**No hacer.** SM-2 completo ni Anki. Bastan intervalos fijos y predecibles.

---

## Fase 2 — Quick wins y pulido

Hacer **después** de Fase 0. Varios son releases pequeños.

### 2.1 Racha y cupo diario

- **Prioridad:** P2
- **Esfuerzo:** bajo
- **Estado:** [ ] Pendiente

**Qué es.** «Llevas 4 días seguidos» y/o «12 / 40 preguntas hoy» en Inicio.

**Cómo.** Contar `attempts.finished_at` por día calendario del usuario (o preguntas respondidas si se guarda en el intento; si no, aproximar por tests terminados). Preferencias: `dailyGoal`. Chip en `HomeScreen`. Sin notificaciones push en el primer corte.

---

### 2.2 Evolución de notas

- **Prioridad:** P2
- **Esfuerzo:** bajo
- **Estado:** [ ] Pendiente

**Qué es.** En Perfil o Historial, tendencia (media por semana o últimos 15 intentos).

**Cómo.** Agregar `percent_score` + `finished_at`. Gráfico mínimo: barras custom o lista «esta semana / anterior». Evitar dependencia pesada si no hace falta (`fl_chart` solo si el dibujo a mano queda peor). Excluir sintéticos o marcarlos.

---

### 2.3 Filtros en Legislación

- **Prioridad:** P2
- **Esfuerzo:** bajo
- **Estado:** [ ] Pendiente

**Qué es.** Junto al orden actual: Todas / Nunca hechas / En curso / Completadas.

**Cómo.** En `laws_screen.dart`, filtrar con los mismos `%` que ya usa `TopicProgressCard` / `statsForTests`. Persistencia tipo `laws_sort_mode`. El candado del orden personalizado no se toca.

---

### 2.4 Compartir e importar un test propio

- **Prioridad:** P2
- **Esfuerzo:** bajo
- **Estado:** [ ] Pendiente

**Qué es.** Exportar **un** test propio (JSON) e importarlo en otra cuenta o dispositivo, sin el backup entero.

**Cómo.** `CustomTestPayloadBuilder` ya genera JSON compatible. Reutilizar `shareBackupFile`. En `CustomTestsHubScreen`: compartir / importar con `file_picker`. Validar con `custom_test_validation.dart`. Idempotencia: mismo id → actualizar o duplicar (decidirlo y documentarlo).

---

### 2.5 Novedades al importar temario

- **Prioridad:** P2
- **Esfuerzo:** medio
- **Estado:** [ ] Pendiente

**Qué es.** Tras importar, «estas leyes/tests no estaban».

**Cómo.** Antes de `importContent`, snapshot de IDs en `sync_meta`. Después, diff. Diálogo o pantalla corta. `SyncService` (versión remota) es otro canal; este punto es el **diff local post-import**.

---

### 2.6 Reloj por pregunta y tema oscuro

- **Prioridad:** P2
- **Esfuerzo:** bajo–medio
- **Estado:** [ ] Pendiente

**Qué es.** (A) Tiempo visible por pregunta, opcional, para ritmo de examen. (B) Tema oscuro para estudiar de noche en tablet.

**Cómo.** (A) `TestPreferences` + reset al cambiar de índice; no sustituye el timer global. (B) `ThemeData` oscuro en `app_theme.dart` y preferencia; probar contraste de `AppTheme.pageBlue` y las cards. La **pausa** queda cubierta por 0.1; no duplicarla aquí.

---

## Orden recomendado de releases

| # | Punto | Versión orientativa |
|---|---|---|
| 1 | 0.1 Continuar test | 1.13.0 |
| 2 | 0.2 Foco del día | 1.14.0 (parche 1.14.1) |
| 3 | 0.3 Búsqueda | 1.15.0 |
| 4 | 1.1 Mapa de débiles | 1.16.0 |
| 5 | 1.2 Simulacro | 1.17.0 |
| 6 | 1.3 Repaso espaciado | 1.18.0 |
| 7+ | Fase 2, uno a uno | 1.19.0 … |

Las versiones son una guía: si un punto se parte, usa parches o dos minors. No hace falta respetar los números si el alcance cambia.

## Convenciones de entrega (igual que ahora)

1. Subir `app/pubspec.yaml` (semver + build).
2. Entrada en `CHANGELOG.md`.
3. Commit `feat: … (vX.Y.Z)`.
4. Tag anotado `vX.Y.Z` y push cuando toque publicar.
5. No incluir `app/*/flutter/generated_*`.
