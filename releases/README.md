# OpoTest — instalación en Android

## APK

| Archivo | Versión |
|---------|---------|
| `OpoTest-v1.6.3-android.apk` | 1.6.3 |

## Instalar la app

1. Copia el APK al móvil (USB, Drive, correo, etc.).
2. En el dispositivo, permite **instalar apps desconocidas** para el navegador o gestor de archivos que uses.
3. Abre el APK y confirma la instalación.

## Temario (contenido)

El APK **no incluye** el temario (~30 MB). Tras instalar:

- **Opción A — copia de contenido:** si tienes un backup exportado desde OpoTest, ve a **Perfil → Configuración → Copias de seguridad → Importar contenido**.
- **Opción B — desarrollo/ADB:** con el móvil conectado por USB, desde el repositorio ejecuta:
  ```powershell
  flutter install --release -d <ID_DISPOSITIVO>
  .\scripts\push-data-android.ps1 -Device <ID_DISPOSITIVO>
  ```
  (Ejecuta el push **después** de instalar; reinstalar borra los datos copiados.)

4. Abre la app y, si hace falta, pulsa **Importar temario** en Configuración.

## Requisitos

- Android 5.0 (API 21) o superior.
- Conexión a internet solo para **Comprobar actualizaciones** (opcional).
