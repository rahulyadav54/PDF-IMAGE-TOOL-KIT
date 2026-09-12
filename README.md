# PDF & Image Toolbox

Offline-first Android utility app for PDF and image manipulation. All core processing happens on-device.

## Requirements

- Flutter 3.27+ (stable)
- Dart 3.6+
- Android SDK with current Play Store target SDK
- Java 17 recommended for Gradle compatibility

## Setup

```bash
flutter pub get
flutter run
```

## Project Structure

```
lib/
  app/          # App shell, routing
  core/         # Theme, constants, utils, errors
  shared/       # Reusable widgets, services, models
  features/     # Feature modules (home, settings, tools, etc.)
```

## Architecture

- **State management:** Riverpod
- **Navigation:** go_router
- **Theme:** Material 3 with light/dark/system modes
- **Privacy:** No backend for core file processing

## Testing

```bash
flutter analyze
flutter test
flutter build apk --debug
```

## Play Store Notes

- Application ID: `com.pdftoolbox.pdf_image_toolbox`
- Release AAB: `build/app/outputs/bundle/release/app-release.aab`
- Signing: copy `android/key.properties.example` → `android/key.properties`
- Store copy: `store_assets/play_store_listing.md`
- Full checklist: `store_assets/RELEASE_CHECKLIST.md`

## Development Phases

See project chat for phased implementation plan. Current status: **All phases complete (0–16)** — ready for Play Store submission after manual checklist items.

### Play Store Readiness (Phase 16)

- **App icon** — adaptive launcher icon generated from `assets/branding/` (brand blue `#1B6EF3`)
- **Splash screen** — light/dark + Android 12 via `flutter_native_splash`
- **Store assets** — `store_assets/play_store_listing.md` and `store_assets/RELEASE_CHECKLIST.md`
- **Release script** — `scripts/build_release.ps1` (analyze → test → AAB)
- **Dynamic version** — Settings shows version from `package_info_plus`
- **Release AAB** — `flutter build appbundle --release` verified

**Regenerate branding (after editing icon):**
```bash
dart run tool/generate_branding.dart
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

**Build for Play Store:**
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

See `store_assets/RELEASE_CHECKLIST.md` for signing, AdMob, IAP, and Play Console steps.

### Security & Privacy (Phase 15)

- Output filename sanitization and safe open/share path validation
- Android backup disabled; unused merged media permissions removed
- UMP ad consent flow before Mobile Ads initialization
- Stronger client-side IAP verification + silent restore on startup
- Temp scan file cleanup on page remove/clear and editor preview rotation
- Privacy policy updated for ads, SDKs, local history, and purchases
- Release build: ProGuard, signing template (`android/key.properties.example`)
- Production AdMob IDs via `--dart-define=ADMOB_APP_ID=...` (and banner/interstitial)

**Before Play Store release:**
1. Create `android/key.properties` from the example file and sign release builds
2. Set real AdMob IDs via dart-define and Gradle `ADMOB_APP_ID`
3. Create IAP products in Play Console
4. Register Syncfusion community license
5. Consider server-side Google Play purchase verification for Pro

### UI/UX Polish (Phase 14)

- Shared `StepBar` (2-step progress) across all tool flows
- Scroll-safe result and error screens
- `EmptyStateCard`, `ResultStatRow`, and `AppSpacing` tokens
- Theme improvements: touch targets, list tiles, theme-aware loading overlay
- Unified empty states on home, recent files, batch, merge, scan, and image-to-PDF
- Simplified home exit (double-back only)
- Privacy screen uses theme text styles

### Scan to PDF (Phase 3)

- Uses `cunning_document_scanner` for edge detection, crop, and perspective correction
- Multi-page scanning with reorder and delete
- Brightness, contrast, and grayscale adjustments via `image` package
- Local PDF generation via `pdf` package
- Share and open via `share_plus` and `open_filex`

### Compress PDF (Phase 4)

- Low / Medium / High compression presets
- **High**: Syncfusion stream compression (preserves text/vectors)
- **Low/Medium**: Page rasterization via `printing` + JPEG rebuild for image-heavy PDFs
- Estimated size shown before processing (clearly labeled)
- Actual size comparison on result screen
- PDF validation (corrupted, empty, oversized files)

**License note:** `syncfusion_flutter_pdf` requires a [Syncfusion community license](https://www.syncfusion.com/sales/communitylicense) for apps under $1M revenue.

### Merge PDF (Phase 5)

- Multi-PDF selection with validation
- Drag-and-drop reordering
- Remove files from queue
- On-device merge via Syncfusion page templates
- Preserves original page sizes where possible
- Progress per file during merge

### Split PDF (Phase 6)

- Extract page range into a single PDF
- Split every page into separate PDFs
- ZIP export for multi-page splits
- Page range validation with friendly errors
- Per-page progress during split

### Image to PDF (Phase 7)

- Multi-image selection (JPG, PNG, WEBP, BMP, GIF)
- Reorder, remove, and preview images
- Page size: A4, Letter, or Fit to Image
- Portrait / landscape orientation
- On-device PDF generation with progress
- Save, share, and open results

### PDF to Image (Phase 8)

- Export PDF pages as JPG or PNG
- All pages or selected page range
- Single image result for one page
- ZIP archive for multiple pages
- Page-by-page processing to reduce memory use
- Per-page export progress

### Image Tools (Phase 9)

**Convert Format**
- Convert JPG, PNG, WEBP, BMP, or GIF to another supported format
- Shows original format, dimensions, and file size
- On-device encoding with alpha flattening for JPG output

**Compress Image**
- Quality slider (20–100%)
- Estimated and actual size comparison
- Preserves original format (JPG/WEBP use quality; PNG uses compression level)

**Resize Image**
- Custom pixel dimensions with aspect ratio lock
- Percentage scaling (10–200%)
- Approximate target file size mode
- Portrait / landscape orientation when aspect ratio is unlocked

### Batch Processing (Phase 10)

- Reusable batch engine with registerable operations
- Convert, compress, or resize multiple images
- Compress multiple PDFs with the same settings
- Per-file progress (`12 / 50`) and per-file error handling
- ZIP export when multiple outputs are created
- Free tier: up to 3 files per batch; Pro: unlimited

### Recent Files (Phase 11)

- Full recent files screen with open, share, and remove actions
- Detects missing/deleted files with clear unavailable state
- Deduplicates by file path and enforces max history (50 entries)
- Remove unavailable files (bulk) from settings or recent files screen
- Clear all history from settings or recent files screen
- Home preview shows latest 5 with View all link

### Ads (Phase 12)

- Centralized `AdService` for Google Mobile Ads
- Home-screen banner (hidden for Pro users)
- Interstitial after successful tool completion (3-minute frequency cap)
- Google test ad unit IDs used in debug builds
- Replace `AdUnitIds` production values before Play Store release

### Pro / IAP (Phase 13)

- Centralized `PurchaseService` with `in_app_purchase`
- Lifetime and monthly Pro products (`ProductIds`)
- Restore purchases from Pro screen and Settings
- Pro granted only after purchase verification on-device
- Pro unlocks: no ads, unlimited batch, unlimited daily operations
- Configure matching products in Google Play Console before testing real purchases
