# Google Play Console — In-App Purchase Setup

Create these products **before** testing real purchases.

## App package
`com.pdftoolbox.pdf_image_toolbox`

## Product 1: Lifetime Pro

| Field | Value |
|-------|-------|
| Product ID | `pdf_toolbox_pro_lifetime` |
| Type | One-time product (non-consumable) |
| Name | DocForge Pro — Lifetime |
| Description | Remove ads, unlimited daily operations, and unlimited batch processing forever. |
| Suggested price | ₹299–₹499 (adjust for your market) |

## Product 2: Monthly Pro

| Field | Value |
|-------|-------|
| Product ID | `pdf_toolbox_pro_monthly` |
| Type | Subscription |
| Base plan ID | `monthly` (or default) |
| Name | DocForge Pro — Monthly |
| Description | Remove ads and unlock unlimited operations. Renews monthly. |
| Suggested price | ₹49–₹99/month |

## Testing steps

1. Play Console → **Setup → License testing** → add your Gmail as license tester
2. Upload a signed AAB to **Internal testing** track
3. Install from Play Store internal test link (not sideloaded APK)
4. Test purchase, restore, and Pro features (no ads, unlimited batch)

## Product IDs in code

Defined in `lib/core/constants/product_ids.dart` — must match Play Console exactly.
