# Compila APK e instalador Windows con la URI de Atlas incrustada (app/mongo_atlas.env.json).
param(
  [switch]$SkipWindows
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root 'app'
$envFile = Join-Path $app 'mongo_atlas.env.json'

if (-not (Test-Path $envFile)) {
  Write-Host "Copia app\mongo_atlas.env.json.example a app\mongo_atlas.env.json y pega tu URI."
  exit 1
}

Set-Location $app
New-Item -ItemType Directory -Force -Path (Join-Path $root 'releases') | Out-Null

Write-Host "APK release..."
flutter build apk --release "--dart-define-from-file=$envFile"
Copy-Item (Join-Path $app 'build\app\outputs\flutter-apk\app-release.apk') (Join-Path $root 'releases\OpoTest-android.apk') -Force

if (-not $SkipWindows) {
  Write-Host "Windows release..."
  flutter build windows --release "--dart-define-from-file=$envFile"
  $iscc = Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'
  if (Test-Path $iscc) {
    & $iscc (Join-Path $root 'scripts\opotest-windows.iss')
  }
}

Write-Host "Listo. Artefactos en releases\"
