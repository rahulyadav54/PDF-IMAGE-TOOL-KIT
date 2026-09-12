# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Google Mobile Ads + UMP consent
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-keep class com.google.android.ump.** { *; }

# Google Play Billing
-keep class com.android.billingclient.** { *; }

# Flutter deferred components (Play Core optional dependency)
-dontwarn com.google.android.play.core.**
