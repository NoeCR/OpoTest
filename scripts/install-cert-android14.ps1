# Guía Android 14: instalar cert mitmproxy manualmente en emulador
param(
    [switch]$Guide,
    [switch]$Verify,
    [switch]$OpenFiles
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$Cert = Join-Path $env:USERPROFILE ".mitmproxy\mitmproxy-ca-cert.cer"
$FindLabel = Join-Path $PSScriptRoot "find-ui-label.cjs"
$ParseTexts = Join-Path $PSScriptRoot "parse-ui-texts.cjs"

function Push-CertFiles {
    if (-not (Test-Path $Cert)) { mitmdump --version | Out-Null }
    & $Adb push $Cert /sdcard/Download/mitmproxy.cer
    & $Adb push $Cert /sdcard/Download/mitmproxy.crt
    if (Test-Path "$env:USERPROFILE\.mitmproxy\mitmproxy-ca-cert.pem") {
        & $Adb push "$env:USERPROFILE\.mitmproxy\mitmproxy-ca-cert.pem" /sdcard/Download/mitmproxy.pem
    }
}

function Tap-Label {
    param([string]$Label, [string]$UiFile)
    $coord = node $FindLabel $Label $UiFile 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $coord) { return $false }
    $x, $y = $coord.Split(',')
    & $Adb shell input tap $x $y
    Start-Sleep -Seconds 2
    return $true
}

function Dump-Ui {
    param([string]$Dest)
    & $Adb shell uiautomator dump /sdcard/ui_wiz.xml | Out-Null
    & $Adb pull /sdcard/ui_wiz.xml $Dest 2>$null | Out-Null
    return $Dest
}

function Start-CertWizard {
    Push-CertFiles
    Write-Host "`n=== Android 14: instalacion manual de certificado CA ===`n"
    Write-Host "Android 14 NO permite instalar CAs desde adb/archivo directamente."
    Write-Host "Trusted credentials solo MUESTRA certificados ya instalados.`n"

    & $Adb shell am start -a android.settings.SETTINGS | Out-Null
    Start-Sleep -Seconds 2

    # Scroll hasta Security & privacy
    1..5 | ForEach-Object {
        & $Adb shell input swipe 540 1800 540 600 300 | Out-Null
        Start-Sleep -Milliseconds 800
    }
    $ui = Dump-Ui "$env:TEMP\ui_wiz1.xml"

    if (-not (Tap-Label "Security" $ui)) {
        Write-Host "No encuentro 'Security & privacy'. Hazlo manualmente:"
        Print-ManualSteps
        return
    }
    $ui = Dump-Ui "$env:TEMP\ui_wiz2.xml"

    if (Tap-Label "More security" $ui) {
        $ui = Dump-Ui "$env:TEMP\ui_wiz3.xml"
    }

    if (Tap-Label "Encryption" $ui) {
        $ui = Dump-Ui "$env:TEMP\ui_wiz4.xml"
    }

    if (Tap-Label "Install a certificate" $ui) {
        $ui = Dump-Ui "$env:TEMP\ui_wiz5.xml"
    }

    if (Tap-Label "CA certificate" $ui) {
        Start-Sleep -Seconds 2
        Write-Host "`n>>> Deberia abrirse el selector de archivos."
        Write-Host ">>> Elige: Download > mitmproxy.cer`n"
    } else {
        Print-ManualSteps
    }
}

function Open-DownloadsInFiles {
    & $Adb shell am start -n com.google.android.documentsui/com.android.documentsui.files.FilesActivity | Out-Null
    Start-Sleep -Seconds 2
    Write-Host "App Files abierta. En Downloads deberias ver: mitmproxy.cer / mitm-ca-cert.crt"
}

function Print-ManualSteps {
    Write-Host @"

Pasos manuales en el emulador (Android 14):

OPCION A — desde Ajustes (recomendado):
  1. Settings > Security & privacy > More security & privacy
  2. Encryption & credentials > Install a certificate > CA certificate
  3. En el selector (solo muestra Drive):
     - Pulsa el menu ≡ arriba a la izquierda
     - Elige "Downloads" (NO Google Drive)
     - O: "sdk_gphone64_x86_64" / "Internal storage" > Download
  4. Selecciona mitmproxy.cer o mitm-ca-cert.crt
  5. Nombre: mitmproxy > OK

OPCION B — si no aparece Downloads en el selector:
  1. Ejecuta: .\scripts\install-cert-android14.ps1 -OpenFiles
  2. Verifica que ves los .cer en Downloads
  3. Vuelve al paso CA certificate del selector y usa el menu ≡

Verificar:
  Encryption & credentials > Trusted credentials > pestaña USER > mitmproxy

"@
}

function Test-CertInstalled {
    & $Adb shell am start -a com.android.settings.TRUSTED_CREDENTIALS_USER | Out-Null
    Start-Sleep -Seconds 2
    $ui = Dump-Ui "$env:TEMP\ui_verify.xml"
    if (Select-String -Path $ui -Pattern "mitmproxy" -Quiet) {
        Write-Host "OK: certificado mitmproxy encontrado en Trusted credentials (USER)."
        return $true
    }
    Write-Host "NO instalado: no aparece mitmproxy en Trusted credentials > USER."
    Print-ManualSteps
    return $false
}

if ($OpenFiles) { Push-CertFiles; Open-DownloadsInFiles; exit }
if ($Verify) { Test-CertInstalled; exit }
if ($Guide -or $PSBoundParameters.Count -eq 0) { Start-CertWizard }
