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

if ($defines.Count -eq 0) {
    Write-Warning "No AdMob dart-defines found — using Dart productionFallback IDs."
    $defines = @(
        "ADMOB_APP_ID=ca-app-pub-1411920894777921~1423517984",
        "ADMOB_BANNER_ID=ca-app-pub-1411920894777921/6727815552",
        "ADMOB_INTERSTITIAL_ID=ca-app-pub-1411920894777921/3777007138"
    )
    $defineArgs = $defines | ForEach-Object { "--dart-define=$_" }
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
