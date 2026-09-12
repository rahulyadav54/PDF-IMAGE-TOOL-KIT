# Play Store Release Checklist

**Last updated:** Phase 16 setup run  
**Signed AAB output:** `build/app/outputs/bundle/release/app-release.aab`

---

## 1. Signing ✅ (automated)

- [x] Upload keystore generated: `android/upload-keystore.jks`
- [x] `android/key.properties` configured
- [x] Credentials saved locally: `android/KEYSTORE_CREDENTIALS.local.txt` (**gitignored — back this up now!**)

> **Action required:** Copy `upload-keystore.jks` and `KEYSTORE_CREDENTIALS.local.txt` to a secure backup (USB drive, password manager, cloud vault). Loss = cannot update the app.

---

## 2. AdMob (production) ⏳ (you must complete)

- [ ] Create AdMob app at [admob.google.com](https://admob.google.com/) for package `com.pdftoolbox.pdf_image_toolbox`
- [ ] Create Banner + Interstitial ad units
- [ ] Fill `android/secrets.local.properties`:
  ```
  ADMOB_APP_ID=ca-app-pub-XXXXXXXX~YYYY
  ADMOB_BANNER_ID=ca-app-pub-XXXXXXXX/ZZZZ
  ADMOB_INTERSTITIAL_ID=ca-app-pub-XXXXXXXX/WWWW
  ```
- [ ] Rebuild: `.\scripts\build_release.ps1`

Until filled, release builds use **Google test ad IDs** (not valid for production).

---

## 3. In-app purchases ⏳ (Play Console)

- [ ] Create products — see `store_assets/PLAY_CONSOLE_IAP_SETUP.md`
  - `pdf_toolbox_pro_lifetime` (one-time)
  - `pdf_toolbox_pro_monthly` (subscription)
- [ ] Add license testers (your Gmail)
- [ ] Upload AAB to **Internal testing** track
- [ ] Test purchase + restore on a real device via Play Store test link

---

## 4. Syncfusion license ⏳ (recommended for commercial release)

- [ ] Register free community license: [syncfusion.com/sales/communitylicense](https://www.syncfusion.com/sales/communitylicense)
- [ ] Keep the license email/confirmation for your records (required for apps under $1M revenue using Syncfusion PDF)

No runtime license key is required for `syncfusion_flutter_pdf` 28.x in this project.

---

## 5. Play Console setup ⏳ (you must complete)

- [x] Store listing copy ready: `store_assets/play_store_listing.md`
- [x] Feature graphic generated: `store_assets/graphics/feature_graphic_1024x500.png`
- [x] Play Store icon (512×512): `store_assets/graphics/play_store_icon_512.png`
- [ ] Create app with package `com.pdftoolbox.pdf_image_toolbox`
- [ ] Upload signed AAB
- [ ] Upload screenshots (capture from device/emulator)
- [ ] Paste store description from `play_store_listing.md`
- [ ] Privacy policy — use in-app text or host publicly and paste URL
- [ ] Data safety — answers in `store_assets/DATA_SAFETY_FORM.md`
- [ ] Content rating — guide in `store_assets/CONTENT_RATING.md`
- [ ] Set countries and pricing

---

## 6. Pre-submit verification

- [x] `flutter analyze` — no issues
- [x] `flutter test` — 48/48 pass
- [x] Signed release AAB builds successfully
- [ ] Install release build on physical device
- [ ] Test: scan, pick file, compress, merge, share, open
- [ ] Test: Pro purchase + restore (after IAP products created)
- [ ] Test: ads show (free) / hidden (Pro) with **production** AdMob IDs

---

## 7. Quick commands

```powershell
# First-time setup (keystore, graphics, secrets template)
.\scripts\setup_release.ps1

# Build signed AAB (reads secrets.local.properties)
.\scripts\build_release.ps1
```

---

## Status summary

| Item | Status |
|------|--------|
| Signing keystore | ✅ Done |
| App icon & splash | ✅ Done |
| Store graphics | ✅ Done |
| Release scripts | ✅ Done |
| Play Console guides | ✅ Done |
| AdMob production IDs | ⏳ Your AdMob account |
| IAP products | ⏳ Play Console |
| Syncfusion license | ⏳ Syncfusion registration |
| Play Console upload | ⏳ Your Play Console account |
| Device testing | ⏳ Physical device |
