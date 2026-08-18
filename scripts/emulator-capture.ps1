# Captura screenshots y tráfico HTTPS en emulador Android (Windows)
# Ejecutar SIEMPRE desde testea-local:
#   cd testea-local
#   .\scripts\emulator-capture.ps1 -StopProxy
# O con ruta completa:
#   & "$PSScriptRoot\emulator-capture.ps1" -StopProxy

param(
    [switch]$InstallCert,
    [switch]$StartProxy,
    [switch]$StopProxy,
    [switch]$Screenshot,
    [switch]$StartSession,
    [int]$IntervalSeconds = 15
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$CapDir = Join-Path $Root "capture"
$ScreensDir = Join-Path $CapDir "screens"
$Cert = Join-Path $env:USERPROFILE ".mitmproxy\mitmproxy-ca-cert.cer"
$Adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

function Ensure-Dirs {
    New-Item -ItemType Directory -Force -Path $CapDir, $ScreensDir | Out-Null
}

function Install-MitmCert {
    if (-not (Test-Path $Cert)) {
        Write-Host "Generando certificado mitmproxy..."
        mitmdump --version | Out-Null
    }
    & $Adb push $Cert /sdcard/Download/mitmproxy.cer
    if (Test-Path (Join-Path $env:USERPROFILE ".mitmproxy\mitmproxy-ca-cert.pem")) {
        & $Adb push (Join-Path $env:USERPROFILE ".mitmproxy\mitmproxy-ca-cert.pem") /sdcard/Download/mitmproxy.pem
    }
    Write-Host @"

CERTIFICADO en Descargas/mitmproxy.cer

IMPORTANTE (Android 14): Trusted credentials NO instala certificados.
Si abres el .cer directamente veras: 'Install CA certificates in Settings'.

Instalacion manual:
  Ajustes > Security & privacy > More security & privacy
  > Encryption & credentials > Install a certificate > CA certificate
  > Download > mitmproxy.cer

Asistente: .\scripts\install-cert-android14.ps1 -Guide
Verificar:  .\scripts\install-cert-android14.ps1 -Verify

"@
    & (Join-Path $PSScriptRoot "install-cert-android14.ps1") -Guide
}

function Start-Proxy {
    Ensure-Dirs
    Get-Process mitmdump -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Process mitmdump -ArgumentList @(
        "-w", (Join-Path $CapDir "traffic.flow"),
        "--listen-host", "0.0.0.0",
        "--listen-port", "8080",
        "-s", (Join-Path $CapDir "log_requests.py")
    ) -WindowStyle Minimized
    & $Adb shell settings put global http_proxy 10.0.2.2:8080
    Write-Host "Proxy activo en 10.0.2.2:8080"
}

function Stop-Proxy {
    Get-Process mitmdump -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-CimInstance Win32_Process -Filter "Name='python.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match 'mitmdump' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    & $Adb shell settings put global http_proxy :0
    Write-Host "Proxy desactivado — la app debería conectar de nuevo."
}

function Save-AdbScreenshot {
    param([string]$DestPath)
    $bytes = & $Adb exec-out screencap -p
    if ($bytes -is [byte[]]) {
        [System.IO.File]::WriteAllBytes($DestPath, $bytes)
    } else {
        [System.IO.File]::WriteAllBytes($DestPath, [System.Text.Encoding]::Latin1.GetBytes([string]$bytes))
    }
}

function Take-Screenshot {
    Ensure-Dirs
    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    $png = Join-Path $ScreensDir "screen_$ts.png"
    Save-AdbScreenshot -DestPath $png
    Write-Host "Screenshot: $png"
    return $png
}

function Start-SessionCapture {
    param([int]$IntervalSeconds = 15)
    Ensure-Dirs
    Write-Host "Captura de sesión cada ${IntervalSeconds}s en $ScreensDir (Ctrl+C para parar)"
    while ($true) {
        $ts = Get-Date -Format "yyyyMMdd_HHmmss"
        Save-AdbScreenshot -DestPath (Join-Path $ScreensDir "screen_$ts.png")
        & $Adb shell uiautomator dump /sdcard/ui.xml 2>$null | Out-Null
        & $Adb pull /sdcard/ui.xml (Join-Path $ScreensDir "ui_$ts.xml") 2>$null | Out-Null
        Start-Sleep -Seconds $IntervalSeconds
    }
}

Ensure-Dirs
if ($InstallCert) { Install-MitmCert }
if ($StartProxy) { Start-Proxy }
if ($StopProxy) { Stop-Proxy }
if ($Screenshot) { Take-Screenshot }
if ($StartSession) { Start-SessionCapture -IntervalSeconds $IntervalSeconds }
if (-not ($InstallCert -or $StartProxy -or $StopProxy -or $Screenshot -or $StartSession)) {
    Write-Host "Uso: -InstallCert | -StartProxy | -StopProxy | -Screenshot | -StartSession [-IntervalSeconds 15]"
}
