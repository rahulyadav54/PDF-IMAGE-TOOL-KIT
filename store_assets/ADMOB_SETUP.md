# AdMob Setup Guide — PDF & Image Toolbox

Follow these steps in order. The app code is already wired; you only need AdMob console IDs.

---

## Step 1 — Create an AdMob account

1. Go to [https://admob.google.com](https://admob.google.com)
2. Sign in with your Google account
3. Accept the AdMob terms if prompted

---

## Step 2 — Register your Android app

1. In AdMob, click **Apps** → **Add app**
2. Choose **No** when asked if the app is on a store (or **Yes** if already published)
3. Platform: **Android**
4. App name: `PDF & Image Toolbox`
5. Package name (must match exactly):

   ```
   com.pdftoolbox.pdf_image_toolbox
   ```

6. Save the app

Copy the **App ID** — it looks like:

```
ca-app-pub-1234567890123456~0987654321
```

---

## Step 3 — Create ad units

Create two ad units for your app:

### Banner (home screen)

1. Open your app in AdMob → **Ad units** → **Add ad unit**
2. Format: **Banner**
3. Name: `Home Banner`
4. Copy the **Ad unit ID** (`ca-app-pub-xxx/yyy`)

### Interstitial (after tool completion)

1. **Add ad unit** again
2. Format: **Interstitial**
3. Name: `Tool Complete Interstitial`
4. Copy the **Ad unit ID**

---

## Step 4 — Add IDs to your project

Open (or create) this file:

```
android/secrets.local.properties
```

Paste your real IDs:

```properties
ADMOB_APP_ID=ca-app-pub-YOUR_APP_ID_HERE
ADMOB_BANNER_ID=ca-app-pub-YOUR_BANNER_ID_HERE
ADMOB_INTERSTITIAL_ID=ca-app-pub-YOUR_INTERSTITIAL_ID_HERE
```

> This file is gitignored. Never commit it or share it publicly.

**Leave values empty** while testing — the app uses Google's official test ad IDs automatically.

---

## Step 5 — Test on your phone (test ads)

1. Connect your Android phone with USB debugging on
2. Run:

   ```powershell
   flutter pub get
   flutter run
   ```

3. On the home screen you should see a **Sponsored** banner at the bottom
4. Complete a tool (e.g. compress an image) — an interstitial may appear after the result screen

Debug builds always use **Google test ad IDs** — safe to click during development.

---

## Step 6 — Build release APK/AAB (real ads)

When your AdMob account is approved and IDs are in `secrets.local.properties`:

```powershell
.\scripts\build_release.ps1
```

Or manually:

```powershell
flutter build apk --release `
  --dart-define=ADMOB_APP_ID=ca-app-pub-YOUR_APP_ID `
  --dart-define=ADMOB_BANNER_ID=ca-app-pub-YOUR_BANNER `
  --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-YOUR_INTERSTITIAL
```

The build script reads `secrets.local.properties` and passes these automatically.

---

## Step 7 — Link AdMob to Play Console (after publishing)

1. Publish your app on Google Play (at least internal testing track)
2. In AdMob → **Apps** → your app → link to Play Store listing
3. In Play Console → **Monetize** → confirm AdMob is connected

New AdMob accounts may take **24–48 hours** before live ads serve. Until then, test ads still work in debug.

---

## Step 8 — Privacy & consent (UMP)

The app requests consent via Google's User Messaging Platform (UMP) where required (e.g. EU).

In AdMob:

1. Go to **Privacy & messaging**
2. Create a **GDPR** message for your app
3. Publish it

No extra code needed — `ConsentService` handles this at startup.

---

## Troubleshooting

| Problem | Fix |
|--------|-----|
| App crashes on launch | Ensure `ADMOB_APP_ID` is a real ID or leave secrets empty for test ID |
| No ads showing | Check internet; wait for AdMob approval; verify IDs in secrets file |
| "Ad failed to load" in log | Normal during development; test IDs should still work |
| Pro user sees ads | Purchase restore may be pending; check Pro screen |

---

## Where ads appear in the app

| Location | Type |
|----------|------|
| Home screen bottom | Banner |
| After completing a tool | Interstitial (max once per 3 minutes) |
| Pro subscribers | No ads |

To disable ads entirely without removing code, set `AdConfig.enabled = false` in `lib/core/constants/ad_config.dart`.
