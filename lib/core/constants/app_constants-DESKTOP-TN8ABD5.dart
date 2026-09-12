/// Application-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'PDF & Image Toolbox';
  static const String appTagline =
      'All your PDF & image tools. Fast. Private. Offline.';

  /// Maximum recent files stored locally.
  static const int maxRecentFiles = 50;

  /// Maximum pages per scan / gallery import session.
  static const int maxScanPages = 30;

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
}
