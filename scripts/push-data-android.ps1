# Copia el temario exportado al emulador/dispositivo Android.
# Uso (desde OpoTest):
#   .\scripts\push-data-android.ps1
#   .\scripts\push-data-android.ps1 -Device emulator-5554
#
# En release (APK instalado): ejecuta push-data DESPUES de flutter install,
# porque reinstalar la app borra /sdcard/Android/data/<package>/.

param(
  [string]$Device = "",
  [string]$Package = "com.opotest.app"
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$data = Join-Path $root "data"
$manifest = Join-Path $data "manifest.json"

if (-not (Test-Path $manifest)) {
  Write-Error "No existe $manifest. Ejecuta antes: node scripts/export-temario.cjs"
}

$adbArgs = @()
if ($Device) { $adbArgs += "-s", $Device }

Write-Host "Comprobando dispositivo..."
& adb @adbArgs get-state | Out-Null

$tmp = "/data/local/tmp/opotest-data"
Write-Host "Subiendo temario (~30 MB) a $tmp ..."
& adb @adbArgs push "$data" $tmp

Write-Host "Copiando al almacenamiento de la app..."
$runAsProbe = (& adb @adbArgs shell "run-as $Package id 2>&1" | Out-String).Trim()
$debuggable = $runAsProbe -notmatch "not debuggable"

if ($debuggable) {
  & adb @adbArgs shell "run-as $Package rm -rf app_flutter/data"
  & adb @adbArgs shell "run-as $Package mkdir -p app_flutter/data"
  & adb @adbArgs shell "run-as $Package cp -r $tmp/. app_flutter/data/"
  Write-Host "Copiado via run-as (build debug)."
} else {
  Write-Host "Build release detectado (run-as no disponible)."
  $extData = "/sdcard/Android/data/$Package/files/data"
  & adb @adbArgs shell "mkdir -p $extData"
  & adb @adbArgs push "$data/." "$extData/"
  Write-Host "Copiado a $extData"
  Write-Host "Abre la app y reinicia, o ve a Configuracion > Importar temario."
}

Write-Host "Listo. Reinicia la app o ve a Perfil > Configuracion > Importar temario."
