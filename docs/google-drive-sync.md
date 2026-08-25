# Sincronizar progreso con Google Drive

OpoTest guarda el JSON de progreso (perfiles, intentos y preguntas marcadas) en la carpeta oculta `appDataFolder` de **tu** Google Drive. No hay servidor de pago: usa los 15 GB de la cuenta.

El temario no se sube a Drive. Solo el progreso.

**No uses variables de entorno del sistema** (`setx`, Panel de control, etc.). La app no las lee. En Windows basta un archivo JSON local; en Android se pasa el ID al **compilar**.

## 1. Proyecto y APIs

1. Entra en [Google Cloud Console](https://console.cloud.google.com/) y selecciona tu proyecto.
2. Activa **Google Drive API** (APIs y servicios > Biblioteca).
3. En **Pantalla de consentimiento OAuth**:
   - Tipo **Externo**.
   - Añade tu Gmail como **usuario de prueba** mientras la app no esté publicada.
   - Ámbitos: `https://www.googleapis.com/auth/drive.appdata` y, si aparece, email/profile.

## 2. Crear los clientes OAuth

En **APIs y servicios > Credenciales > Crear credenciales > ID de cliente de OAuth**, crea **tres** clientes:

| Tipo | Para qué | Qué copias después |
|---|---|---|
| **Aplicación de escritorio** | Login en Windows (se abre el navegador) | ID de cliente **y** secreto |
| **Aplicación web** | Android (`server_client_id`) | Solo el ID de cliente (no es secreto) |
| **Android** | Que Google acepte la app firmada | Nada que pegar en el JSON; hay que registrar package + SHA-1 |

Cliente **Android** (en el formulario de Google Cloud):

- Nombre de paquete: `com.opotest.app`
- Huella del certificado SHA-1: la del variant **debug** / alias `AndroidDebugKey`

En Windows hay que usar `gradlew.bat` (no `.\gradlew`):

```powershell
cd app\android
.\gradlew.bat signingReport
```

En el informe busca el primer bloque `Variant: debug` y copia la línea `SHA1:` (con los dos puntos). Si `gradlew.bat` falla, equivale:

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

## 3. Cómo dar las credenciales a la app

### Windows (lo habitual al desarrollar)

Copia el ejemplo y rellena los valores reales:

```powershell
copy app\google_oauth.json.example app\google_oauth.json
```

| Campo | De qué cliente sale |
|---|---|
| `desktop_client_id` | ID del cliente **escritorio** (`….apps.googleusercontent.com`) |
| `desktop_client_secret` | Secreto del cliente **escritorio** (`GOCSPX-…`) |
| `server_client_id` | ID del cliente **web** (para cuando compiles Android) |

`app/google_oauth.json` **no se sube a git**. Arranca la app desde `app/`:

```powershell
cd app
flutter run -d windows
```

Si más adelante generas un `.exe`, copia `google_oauth.json` **junto al ejecutable**.

### Android (el JSON del PC no viaja al móvil)

Al ejecutar o construir, pasa el ID **web**:

```powershell
cd app
flutter run -d <dispositivo> --dart-define=GOOGLE_OAUTH_SERVER_CLIENT_ID=TU_ID_WEB.apps.googleusercontent.com
```

`--dart-define` se incrusta en la compilación. **No** es una variable de entorno de Windows.

## 4. Uso en la app

En **Perfil**:

1. Iniciar sesión con Google (la misma cuenta en PC, tablet y móvil).
2. Acepta el acceso. La primera vez Google puede avisar de que la app no está verificada: elige Continuar (con el usuario de prueba).
3. **Sincronizar ahora** (también se hace al abrir la app si hay sesión, y al terminar un test).

Los intentos se **fusionan por id**: no se borra lo que ya tengas en el dispositivo ni se cambia el usuario activo local.
