# DocForge Marketing Website

Static marketing site for **DocForge — PDF Editor & Tools**, hosted on Vercel.

## Pages

| URL | Description |
|-----|-------------|
| `/` | Landing page with features and Play Store CTA |
| `/privacy` | Privacy policy (required for Google Play) |
| `/terms` | Terms of use |

## Local preview

Open `index.html` in a browser, or serve the folder with any static server:

```powershell
cd website
npx --yes serve .
```

Then visit `http://localhost:3000`.

## Deploy to Vercel

### Option A: Vercel dashboard (recommended)

1. Push this repo to GitHub (if not already).
2. Go to [vercel.com/new](https://vercel.com/new) and import the repository.
3. Set **Root Directory** to `website`.
4. Deploy. Vercel assigns a URL like `https://your-project.vercel.app`.

### Option B: Vercel CLI

```powershell
cd website
npx vercel --prod
```

Follow the prompts to link or create a project. Use project name `docforge-pdf` for a URL like `https://docforge-pdf.vercel.app`.

## After deploy

1. Copy your live URL (e.g. `https://docforge-pdf.vercel.app`).
2. Confirm `/privacy` loads in a browser.
3. Paste `https://YOUR-URL.vercel.app/privacy` into **Google Play Console → App content → Privacy policy**.
4. If the Vercel URL differs from `docforge-pdf.vercel.app`, update `privacyPolicyUrl` in `lib/core/constants/app_constants.dart`.

## Custom domain (later)

When you buy `pdftoolbox.app`:

1. Vercel → Project → **Settings** → **Domains** → Add `pdftoolbox.app` and `www.pdftoolbox.app`.
2. Update DNS at your registrar per Vercel's instructions.
3. Change `privacyPolicyUrl` in the app to `https://pdftoolbox.app/privacy`.
4. Ship an app update (or wait for the next release).

No site changes are required — the same static files work on both domains.

## Updating content

- **Privacy policy:** Edit `privacy/index.html` (source of truth: `store_assets/PRIVACY_POLICY.md`).
- **Terms:** Edit `terms/index.html`.
- **Marketing copy:** Edit `index.html` (source: `store_assets/play_store_listing.md`).
