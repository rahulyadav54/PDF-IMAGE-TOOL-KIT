/// Production secrets injected at build time via --dart-define.
class ReleaseSecrets {
  ReleaseSecrets._();

  static const String syncfusionLicenseKey = String.fromEnvironment(
    'SYNCFUSION_LICENSE_KEY',
    defaultValue: '',
  );

  static const String admobAppId = String.fromEnvironment(
    'ADMOB_APP_ID',
    defaultValue: '',
  );

  static const String admobBannerId = String.fromEnvironment(
    'ADMOB_BANNER_ID',
    defaultValue: '',
  );

  static const String admobInterstitialId = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ID',
    defaultValue: '',
  );

  static bool get hasSyncfusionLicense => syncfusionLicenseKey.isNotEmpty;
}
