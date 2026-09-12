/// Application-wide constants.
class AppConstants {
  AppConstants._();

  /// Compact label for launcher, task switcher, and tight UI.
  static const String appNameShort = 'DocForge';

  /// Full user-facing product name.
  static const String appName = 'DocForge — PDF Editor & Tools';

  static const String appTagline = 'PDF Editor & Tools';

  static const String companyName = 'ZAYA CODE HUB';
  static const String supportEmail = 'zayacodehub@gmail.com';
  static const String supportPhone = '+917033399183';
  static const String privacyPolicyUrl =
      'https://docforge-pdf.vercel.app/privacy';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.pdftoolbox.pdf_image_toolbox';
  static const String companyCreditLabel = 'Developed by';
  static const String companyPoweredLabel = 'Powered by';
  static const String companyCredit = '$companyCreditLabel $companyName';
  static const String companyPowered = '$companyPoweredLabel $companyName';
  static const String copyright = '© 2026 $companyName';

  /// Maximum recent files stored locally.
  static const int maxRecentFiles = 50;

  /// Maximum pages per scan / gallery import session.
  static const int maxScanPages = 200;

  /// Maximum images per image-to-PDF batch.
  static const int maxImageToPdfBatch = 200;

  /// Maximum files per batch processor queue.
  static const int maxBatchProcessorFiles = 200;

  /// Preview dimension for fast enhancement preview (not full resolution).
  static const int enhancementPreviewMaxDimension = 720;

  /// Maximum size for files opened or shared into the app.
  static const int maxIncomingFileBytes = 150 * 1024 * 1024;

  /// SharedPreferences keys.
  static const String themeModeKey = 'theme_mode';
  static const String recentFilesKey = 'recent_files';
  static const String dailyOpsCountKey = 'daily_ops_count';
  static const String dailyOpsDateKey = 'daily_ops_date';
  static const String pdfQualityKey = 'pdf_quality';
  static const String compressionLevelKey = 'compression_level';
  static const String exportFormatKey = 'export_format';
  static const String imageCompressQualityKey = 'image_compress_quality';
  static const String starredFilesKey = 'starred_files';
  static const String pinnedToolsKey = 'pinned_tools';
  static const String appLockEnabledKey = 'app_lock_enabled';
  static const String appLockBiometricKey = 'app_lock_biometric';
  static const String vaultPinHashKey = 'vault_pin_hash';
  static const String vaultFilesKey = 'vault_files';
  static const String fileTagsKey = 'file_tags';
  static const String fileFoldersKey = 'file_folders';
  static const String localeKey = 'app_locale';
  static const String savedBytesKey = 'saved_bytes_total';
  static const String proStatusKey = 'pro_status';
  static const String proProductIdKey = 'pro_product_id';
  static const String proPurchaseIdKey = 'pro_purchase_id';

  /// Free tier: max files per batch operation.
  static const int freeBatchFileLimit = 3;

  /// Free tier: max tool operations per day.
  static const int freeDailyOperationLimit = 5;
}
