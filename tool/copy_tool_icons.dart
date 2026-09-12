// ignore_for_file: avoid_print

import 'dart:io';

import 'package:image/image.dart';

/// Copies individual tool icons from the source folder into assets/tools/.
///
/// Source (read-only): tools icon/*.png
/// Output: assets/tools/[tool_id].png
///
/// Does not modify files in the source folder.
void main() {
  const sourceDir = r'tools icon';
  const outputDir = 'assets/tools';

  // Verified mapping from image content (Sep 2026 individual icons).
  const mapping = <String, String>{
    'ChatGPT Image Sep 11, 2026, 04_56_09 PM.png': 'scan_to_pdf',
    'ChatGPT Image Sep 11, 2026, 04_57_25 PM.png': 'compress_pdf',
    'ChatGPT Image Sep 11, 2026, 04_58_54 PM.png': 'merge_pdf',
    'ChatGPT Image Sep 11, 2026, 05_00_28 PM.png': 'split_pdf',
    'ChatGPT Image Sep 11, 2026, 05_01_27 PM.png': 'image_to_pdf',
    'ChatGPT Image Sep 11, 2026, 05_02_25 PM.png': 'pdf_to_image',
    'ChatGPT Image Sep 11, 2026, 05_07_58 PM.png': 'convert_format',
    'ChatGPT Image Sep 11, 2026, 05_09_04 PM.png': 'compress_image',
    'ChatGPT Image Sep 11, 2026, 05_10_51 PM.png': 'resize_image',
    'ChatGPT Image Sep 11, 2026, 05_12_36 PM.png': 'stitch_images',
    'ChatGPT Image Sep 11, 2026, 05_13_54 PM.png': 'id_photo_maker',
    'ChatGPT Image Sep 11, 2026, 05_17_25 PM.png': 'batch_processing',
    'ChatGPT Image Sep 11, 2026, 05_19_23 PM.png': 'rotate_reorder',
  };

  final source = Directory(sourceDir);
  if (!source.existsSync()) {
    print('Source folder not found: $sourceDir');
    exit(1);
  }

  Directory(outputDir).createSync(recursive: true);

  var copied = 0;
  for (final entry in mapping.entries) {
    final sourcePath = '$sourceDir/${entry.key}';
    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      print('SKIP missing source: ${entry.key}');
      continue;
    }

    final decoded = decodeImage(sourceFile.readAsBytesSync());
    if (decoded == null) {
      print('SKIP could not decode: ${entry.key}');
      continue;
    }

    print('${entry.key} (${decoded.width}x${decoded.height}) -> ${entry.value}.png');

    final square = _fitSquare(decoded, size: 512);
    final outPath = '$outputDir/${entry.value}.png';
    File(outPath).writeAsBytesSync(encodePng(square));
    copied++;
  }

  // Remove any PNGs not produced by this script (old sprite crops, etc.).
  final expectedOutputs = mapping.values.toSet();
  for (final file in Directory(outputDir).listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last.replaceAll('.png', '');
    if (!expectedOutputs.contains(name)) {
      file.deleteSync();
      print('Removed stale asset: ${file.path}');
    }
  }

  print('Done — $copied tool icons copied to $outputDir/');
  print('Missing custom assets (using Material icon fallback in app):');
  for (final id in [
    'lock_pdf',
    'upgrade_pro',
    'settings',
    'recent_files',
    'privacy_security',
  ]) {
    if (!File('$outputDir/$id.png').existsSync()) {
      print('  - $id');
    }
  }
}

Image _fitSquare(Image source, {required int size}) {
  if (source.width == source.height && source.width == size) {
    return source;
  }

  final side = source.width < source.height ? source.width : source.height;
  final x = ((source.width - side) / 2).round();
  final y = ((source.height - side) / 2).round();
  final cropped = copyCrop(source, x: x, y: y, width: side, height: side);
  return copyResize(cropped, width: size, height: size);
}
