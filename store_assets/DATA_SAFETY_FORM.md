# Play Console — Data Safety Form Answers

Use these answers when completing the Data safety section. Adjust if your production setup changes.

## Does your app collect or share user data?
**Yes** — limited data via third-party SDKs (Google Ads, Google Play Billing). Core file processing does not upload user documents.

## Data types

| Data type | Collected? | Shared? | Purpose | Required? |
|-----------|------------|---------|---------|-----------|
| Files and docs (PDFs/images) | No (processed on-device) | No | — | — |
| App activity (recent files metadata) | Yes, locally only | No | App functionality | No |
| Device or other IDs (Advertising ID) | Yes, via AdMob | Yes, with Google | Advertising | No (Pro removes ads) |
| Purchase history | Yes, via Google Play | With Google | App functionality | No |
| Crash logs | Optional via Play Console | With Google | Analytics | No |

## Security practices
- Data encrypted in transit (HTTPS for ads/billing SDKs)
- Users can request deletion of local history (Clear recent files in Settings)
- Android backup disabled for the app

## Privacy policy
Reference the in-app Privacy Policy screen (`/privacy`) or host the same text at a public URL and paste that URL in Play Console.

Suggested statement for the form:
> PDF & Image Toolbox processes files locally on the device. Recent file history is stored locally and can be cleared by the user. The free version may show Google ads. Purchases are handled by Google Play.
