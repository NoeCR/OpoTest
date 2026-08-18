# Copia el temario exportado al emulador/dispositivo Android.
# Uso (desde testea-local):
#   .\scripts\push-data-android.ps1
#   .\scripts\push-data-android.ps1 -Device emulator-5554

param(
  [string]$Device = "",
  [string]$Package = "com.testea.local.testea_local"
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

$tmp = "/data/local/tmp/testea-data"
Write-Host "Subiendo temario (~30 MB) a $tmp ..."
& adb @adbArgs push "$data" $tmp

Write-Host "Copiando al almacenamiento privado de la app..."
& adb @adbArgs shell "run-as $Package rm -rf app_flutter/data"
& adb @adbArgs shell "run-as $Package mkdir -p app_flutter/data"
& adb @adbArgs shell "run-as $Package cp -r $tmp/. app_flutter/data/"

Write-Host "Listo. Reinicia la app o ve a Perfil > Configuracion > Importar temario."
