# Testea Local

Réplica offline de **Testea** con contenido local, cuentas locales y sync opcional cada 7 días.

## 1. Exportar temario completo

```bash
cd testea-local
node scripts/export-temario.cjs --concurrency=10
```

Salida en `data/`:
- `laws-index.json`, `hierarchy.json`, `options.json`
- `laws/{id}/...` — jerarquía ley/título/capítulo
- `tests/{id}.json` — cada test con preguntas y `textClarification_es`
- `manifest.json` — estadísticas de exportación

Reanudar tests fallidos:

```bash
node scripts/export-temario.cjs --resume --concurrency=10
```

## 2. Captura emulador (screenshots; HTTPS opcional)

**Recomendado:** usar Testea **sin proxy** para navegar la app. El temario ya está exportado vía API directa.

```powershell
cd testea-local
.\scripts\emulator-capture.ps1 -Screenshot    # PNG en capture/screens/
.\scripts\emulator-capture.ps1 -StopProxy
```

### Proxy HTTPS (avanzado, Android 14)

En Android 14 la app puede quedarse en splash con proxy activo. Si necesitas capturar tráfico:

```powershell
.\scripts\emulator-capture.ps1 -InstallCert
# Ajustes > Seguridad > Instalar certificado > Certificado CA
# Menú ≡ > Downloads > mitmproxy.cer (no uses el selector de Drive)
.\scripts\emulator-capture.ps1 -StartProxy
```

## 3. App Flutter

```bash
cd testea-local/app
flutter pub get
flutter run -d windows   # o android
```

**Primera ejecución:** importa automáticamente desde `../data` (desktop) o desde la carpeta empujada al dispositivo (Android).

### Android / emulador

El temario no vive dentro del APK. Empújalo una vez:

```powershell
cd testea-local
.\scripts\push-data-android.ps1 -Device emulator-5554
```

Luego reinicia la app o **Perfil → Configuración → Importar temario**.

### Características

- Barra inferior **Tests / Perfil** (como Testea)
- Cuentas **100% locales** (crear / cambiar / borrar progreso)
- Navegación: Legislación → Títulos → Capítulos → Grid de tests con **Nota media / Mejor nota**
- Tests, respuestas e intentos en **SQLite**
- Sesión con **Índice** de preguntas, contador "Completadas X de Y"
- Resultados con **Nota neta**, grid de respuestas y review con **nota aclaratoria**
- Test aleatorio desde el temario importado
- Exportar progreso JSON (resumen + intentos) en **Perfil**
- Sync: solo comprueba versión remota; reimportas cuando quieras

## Estructura

```
testea-local/
  scripts/export-temario.cjs
  scripts/emulator-capture.ps1
  data/                 # export (gitignore parcial)
  app/                  # Flutter (lib/screens, database, services)
```
