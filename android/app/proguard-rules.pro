# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

# App code
-keep class com.pdftoolbox.pdf_image_toolbox.** { *; }

# Kotlin metadata
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# Google Mobile Ads + UMP consent
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-keep class com.google.android.ump.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Google Play Billing + in-app purchase plugin
-keep class com.android.billingclient.** { *; }
-keep class io.flutter.plugins.inapppurchase.** { *; }

# ML Kit
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Local auth / biometrics
-keep class androidx.biometric.** { *; }

# Gson / reflection used by plugins
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Flutter deferred components (Play Core optional dependency)
-dontwarn com.google.android.play.core.**

# Syncfusion / PDF native bridges
-dontwarn com.syncfusion.**
