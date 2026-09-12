# Build a signed release APK with AdMob IDs from secrets.local.properties.
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

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

# OneDrive can lock the build folder — try to clear it first.
if (Test-Path "build") {
    Write-Host "Clearing build folder..."
    try {
        Remove-Item -Recurse -Force "build" -ErrorAction Stop
    } catch {
        Write-Warning "Could not delete build folder. Pause OneDrive sync and close Android Studio, then retry."
    }
}

Write-Host "Running flutter analyze..."
flutter analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Building release APK..."
if ($defineArgs.Count -gt 0) {
    flutter build apk --release @defineArgs
} else {
    flutter build apk --release
}

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Success! Install on your phone:" -ForegroundColor Green
    Write-Host "  build/app/outputs/flutter-apk/app-release.apk"
}
