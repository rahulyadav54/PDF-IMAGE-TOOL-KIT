# Build a signed release App Bundle for Google Play.
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

if (-not (Test-Path "android/key.properties")) {
    Write-Error "Run scripts/setup_release.ps1 first to create signing config."
}

$defines = @()
$secretsPath = "android/secrets.local.properties"
if (Test-Path $secretsPath) {
    Get-Content $secretsPath | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $val = $matches[2].Trim()
            if ($val -and $key -match '^ADMOB_') {
                $defines += "$key=$val"
            }
        }
    }
}

$defineArgs = $defines | ForEach-Object { "--dart-define=$_" }

if (-not (Test-Path $secretsPath)) {
    Write-Warning "android/secrets.local.properties not found — using test AdMob IDs."
} elseif ($defines.Count -eq 0) {
    Write-Warning "secrets.local.properties is empty — fill AdMob + Syncfusion keys for production."
}

Write-Host "Running flutter analyze..."
flutter analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Running tests..."
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Building signed release app bundle..."
if ($defineArgs.Count -gt 0) {
    flutter build appbundle --release @defineArgs
} else {
    flutter build appbundle --release
}

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Success! Upload to Play Console:" -ForegroundColor Green
    Write-Host "  build/app/outputs/bundle/release/app-release.aab"
}
