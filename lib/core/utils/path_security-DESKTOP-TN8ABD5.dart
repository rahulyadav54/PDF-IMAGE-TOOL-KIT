import 'dart:io';

import 'package:path/path.dart' as p;

/// Filename and path safety helpers to prevent traversal and unsafe writes.
class PathSecurity {
  PathSecurity._();

  static final _unsafeChars = RegExp(r'[\\/:*?"<>|]');

  /// Returns a single-segment filename safe for writing under an output directory.
  static String sanitizeFileName(String fileName) {
    final base = p.basename(fileName.trim());
    final cleaned = base.replaceAll(_unsafeChars, '_');
    if (cleaned.isEmpty || cleaned == '.' || cleaned == '..') {
      throw const FormatException('Invalid output filename.');
    }
    return cleaned;
  }

  /// Joins [outputDir] and [fileName] after sanitizing the filename segment.
  static String outputPath(String outputDir, String fileName) {
    final safeName = sanitizeFileName(fileName);
    final resolved = p.normalize(p.join(outputDir, safeName));
    final normalizedDir = p.normalize(outputDir);

    if (!p.isWithin(normalizedDir, resolved) && resolved != normalizedDir) {
      throw const FormatException('Invalid output path.');
    }
    return resolved;
  }

  /// Validates that [path] exists as a regular file before open/share actions.
  static Future<void> assertSafeReadableFile(String path) async {
    if (path.isEmpty) {
      throw const FormatException('File path is empty.');
    }

    final normalized = p.normalize(path);
    if (normalized.contains('..')) {
      throw const FormatException('Invalid file path.');
    }

    final file = File(normalized);
    if (!await file.exists()) {
      throw const FormatException('File no longer exists.');
    }

    final type = await FileSystemEntity.type(normalized);
    if (type != FileSystemEntityType.file) {
      throw const FormatException('Invalid file path.');
    }
  }
}
