import 'package:flutter/foundation.dart';

import 'ad_config.dart';

/// AdMob unit IDs. Debug builds always use Google test IDs.
///
/// Release builds prefer `--dart-define` values (see `scripts/build_apk.ps1`).
/// If those are missing, [productionFallback] IDs from `secrets.local.properties`
/// are used so manifest App ID and Dart ad units always match.
class AdUnitIds {
  AdUnitIds._();

  static const String testAndroidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitial = 'ca-app-pub-3940256099942544/1033173712';

  /// Keep in sync with `android/secrets.local.properties`.
  static const productionFallback = (
    appId: 'ca-app-pub-1411920894777921~1423517984',
    banner: 'ca-app-pub-1411920894777921/6727815552',
    interstitial: 'ca-app-pub-1411920894777921/3777007138',
  );

  static const String _productionAndroidAppId = String.fromEnvironment(
    'ADMOB_APP_ID',
    defaultValue: '',
  );
  static const String _productionBanner = String.fromEnvironment(
    'ADMOB_BANNER_ID',
    defaultValue: '',
  );
  static const String _productionInterstitial = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ID',
    defaultValue: '',
  );

  static String get androidAppId {
    if (kDebugMode) return testAndroidAppId;
    if (_productionAndroidAppId.isNotEmpty) return _productionAndroidAppId;
    if (AdConfig.enabled) return productionFallback.appId;
    return testAndroidAppId;
  }

  static String get banner {
    if (kDebugMode) return testBanner;
    if (_productionBanner.isNotEmpty) return _productionBanner;
    if (AdConfig.enabled) return productionFallback.banner;
    return testBanner;
  }

  static String get interstitial {
    if (kDebugMode) return testInterstitial;
    if (_productionInterstitial.isNotEmpty) return _productionInterstitial;
    if (AdConfig.enabled) return productionFallback.interstitial;
    return testInterstitial;
  }

  static bool get isUsingPlaceholderProductionIds {
    if (kDebugMode) return false;
    return _productionAndroidAppId.isEmpty &&
        _productionBanner.isEmpty &&
        _productionInterstitial.isEmpty &&
        !AdConfig.enabled;
  }
}
