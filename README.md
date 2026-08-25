# OpoTest

App Flutter offline para practicar tests de oposiciones con temario local, progreso por usuario y métricas de rendimiento.

## Qué hace este repositorio

- Ejecuta una app móvil/escritorio en Flutter (`app/`).
- Carga legislación y tests desde datos locales (`data/`).
- Permite cuentas locales y persistencia en SQLite.
- Guarda intentos, estadísticas y progreso (`hechos/total`) por bloque.
- Incluye scripts para exportar/actualizar contenido y para uso en emulador Android.

## Arranque rápido

### 1) Preparar app

```bash
cd app
flutter pub get
```

### 2) Ejecutar

```bash
flutter run -d windows
# o en Android/emulador
flutter run -d emulator-5554
```

### 3) Cargar temario en Android (si aplica)

```powershell
cd ..
.\scripts\push-data-android.ps1 -Device emulator-5554
```

Luego reinicia la app o usa la importación desde Configuración.

## Características principales

- Navegación jerárquica: ley → título → capítulo/sección/artículo.
- Selector por tipo de contenido: tests, exámenes, preguntas oficiales y preguntas propias.
- Sesión de examen con tiempo, avance y revisión.
- Resultados con métricas (aciertos, fallos, sin responder, tiempo).
- Notas aclaratorias con render HTML.
- Persistencia local de progreso por usuario.
- Sincronización opcional del progreso con Google Drive (misma cuenta en Windows, tablet y móvil). Ver `docs/google-drive-sync.md`.

## Estructura del repositorio

```text
OpoTest/
  app/       # Aplicación Flutter
  data/      # Contenido local de legislación/tests
  scripts/   # Utilidades de exportación, captura y carga en emulador
```

## Documentación de cambios

Revisa `CHANGELOG.md` para el historial de versiones y funcionalidades.
