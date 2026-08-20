# Genera JSON de contenido importable desde la app (sin ADB ni scripts en el móvil).
# Uso (desde la raíz del repo):
#   .\scripts\export-content-backup.ps1
#   .\scripts\export-content-backup.ps1 -Version 1.6.3

param(
  [string]$Version = "",
  [string]$DataDir = "",
  [string]$Output = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$app = Join-Path $root "app"
$data = if ($DataDir) { $DataDir } else { Join-Path $root "data" }
$manifest = Join-Path $data "manifest.json"

if (-not (Test-Path $manifest)) {
  Write-Error "No existe $manifest. Ejecuta antes: node scripts/export-temario.cjs"
}

$fileName = if ($Version) { "OpoTest-content-v$Version.json" } else { "OpoTest-content.json" }
$out = if ($Output) { $Output } else { Join-Path $root "releases" $fileName }

Write-Host "Generando copia de contenido..."
Push-Location $app
try {
  $env:OPOTEST_DATA_PATH = $data
  $env:OPOTEST_OUTPUT = $out
  flutter test test/tools/export_content_backup_tool_test.dart --plain-name "generates content backup json"
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
  Remove-Item Env:OPOTEST_DATA_PATH -ErrorAction SilentlyContinue
  Remove-Item Env:OPOTEST_OUTPUT -ErrorAction SilentlyContinue
  Pop-Location
}

Write-Host "Listo. Comparte releases\$fileName junto al APK."
