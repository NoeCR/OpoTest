# OpoTest — instalación en Android

## Paquete para compartir

| Archivo | Descripción | Tamaño aprox. |
|---------|-------------|---------------|
| `OpoTest-v1.6.3-android.apk` | Aplicación | ~24 MB |
| `OpoTest-content-v1.6.3.json` | Temario completo (leyes + tests oficiales) | ~28 MB |

Envía **ambos archivos** a quien quiera probar la app.

## Instalar la app

1. Copia el APK al móvil (USB, Drive, correo, etc.).
2. En el dispositivo, permite **instalar apps desconocidas** para el navegador o gestor de archivos que uses.
3. Abre el APK y confirma la instalación.

## Importar el temario (JSON)

1. Copia `OpoTest-content-v1.6.3.json` al móvil.
2. Abre OpoTest → **Perfil → Configuración → Copias de seguridad**.
3. Pulsa **Importar contenido** y selecciona el JSON.
4. Espera a que termine (puede tardar 1–2 min). Verás un resumen con leyes y tests importados.

No hace falta ordenador ni cables: solo el APK y este JSON.

## Regenerar el JSON (mantenedores)

Desde la raíz del repositorio, con la carpeta `data/` exportada:

```powershell
.\scripts\export-content-backup.ps1 -Version 1.6.3
```

## Alternativa ADB (solo desarrollo)

```powershell
flutter install --release -d <ID_DISPOSITIVO>
.\scripts\push-data-android.ps1 -Device <ID_DISPOSITIVO>
```

(Ejecuta el push **después** de instalar; reinstalar borra los datos copiados.)

## Requisitos

- Android 5.0 (API 21) o superior.
- Conexión a internet solo para **Comprobar actualizaciones** (opcional).
