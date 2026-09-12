# One-time release setup: keystore, key.properties, secrets template, store graphics.
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "=== DocForge - Release Setup ===" -ForegroundColor Cyan

# 1. Keystore
$keystorePath = "android/upload-keystore.jks"
$credPath = "android/KEYSTORE_CREDENTIALS.local.txt"

if (-not (Test-Path $keystorePath)) {
    $keyPass = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 24 | ForEach-Object {[char]$_})
    keytool -genkeypair -v -keystore $keystorePath -keyalg RSA -keysize 2048 -validity 10000 -alias upload `
        -storepass $keyPass -keypass $keyPass `
        -dname "CN=PDF Image Toolbox, OU=Mobile, O=PDF Toolbox, L=Chennai, ST=Tamil Nadu, C=IN"
    @"
DocForge - Upload Keystore Credentials
=================================================
KEEP THIS FILE PRIVATE. Back up upload-keystore.jks with these passwords.

Keystore file : android/upload-keystore.jks
Key alias     : upload
Store password: $keyPass
Key password  : $keyPass
Generated     : $(Get-Date -Format 'yyyy-MM-dd HH:mm')
"@ | Set-Content $credPath -Encoding UTF8
    Write-Host "[OK] Created upload keystore and $credPath" -ForegroundColor Green
} else {
    Write-Host "[SKIP] Keystore already exists" -ForegroundColor Yellow
}

# 2. key.properties
if (-not (Test-Path "android/key.properties")) {
    $content = Get-Content $credPath -Raw
    $pass = ([regex]::Match($content, 'Store password: (.+)')).Groups[1].Value.Trim()
    @"
storePassword=$pass
keyPassword=$pass
keyAlias=upload
storeFile=../upload-keystore.jks
"@ | Set-Content "android/key.properties" -Encoding ASCII
    Write-Host "[OK] Created android/key.properties" -ForegroundColor Green
} else {
    Write-Host "[SKIP] key.properties already exists" -ForegroundColor Yellow
}

# 3. secrets template
if (-not (Test-Path "android/secrets.local.properties")) {
    Copy-Item "android/secrets.local.properties.example" "android/secrets.local.properties"
    Write-Host "[OK] Created android/secrets.local.properties — fill in AdMob + Syncfusion keys" -ForegroundColor Green
} else {
    Write-Host "[SKIP] secrets.local.properties already exists" -ForegroundColor Yellow
}

# 4. Store graphics
Write-Host "Generating branding and store graphics..."
dart run tool/generate_branding.dart
dart run flutter_launcher_icons
dart run flutter_native_splash:create

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Back up android/upload-keystore.jks and KEYSTORE_CREDENTIALS.local.txt"
Write-Host "  2. Fill android/secrets.local.properties with production AdMob IDs"
Write-Host "  3. Run: .\scripts\build_release.ps1"
Write-Host "  4. Follow store_assets/RELEASE_CHECKLIST.md for Play Console upload"
