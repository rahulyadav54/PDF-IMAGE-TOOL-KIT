/// Formats byte counts into human-readable units (B, KB, MB, GB).
class FileSizeFormatter {
  FileSizeFormatter._();

  static String format(int bytes) {
    if (bytes < 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${_formatValue(bytes / 1024)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${_formatValue(bytes / (1024 * 1024))} MB';
    }
    return '${_formatValue(bytes / (1024 * 1024 * 1024))} GB';
  }

  /// Returns saved percentage between original and new sizes.
  static int? savedPercent(int originalBytes, int newBytes) {
    if (originalBytes <= 0 || newBytes >= originalBytes) return null;
    return (((originalBytes - newBytes) / originalBytes) * 100).round();
  }

  static String _formatValue(double value) {
    if (value >= 100) return value.toStringAsFixed(0);
    if (value >= 10) return value.toStringAsFixed(1);
    return value.toStringAsFixed(2);
  }
}
