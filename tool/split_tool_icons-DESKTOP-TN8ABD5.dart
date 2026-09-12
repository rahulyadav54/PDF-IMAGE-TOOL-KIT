// ignore_for_file: avoid_print

import 'dart:io';

import 'package:image/image.dart';

/// Legacy sprite-sheet splitter. Prefer [copy_tool_icons.dart] for individual PNGs.
///
/// Source (read-only): tools icon/icons.png
/// Output: assets/tools/*.png
void main() {
  const sourcePath = r'tools icon/icons.png';
  const outputDir = 'assets/tools';

  final sourceFile = File(sourcePath);
  if (!sourceFile.existsSync()) {
    print('Source not found: $sourcePath');
    exit(1);
  }

  final sheet = decodeImage(sourceFile.readAsBytesSync());
  if (sheet == null) {
    print('Could not decode source image.');
    exit(1);
  }

  print('Sheet size: ${sheet.width}x${sheet.height}');

  // 3 columns x 6 rows of tool cards (18 tools), proportional crop per cell.
  const columns = 3;
  const rows = 6;

  final cellW = sheet.width / columns;
  final cellH = sheet.height / rows;

  // Row-major order matching the marketing sheet layout.
  const toolIds = [
    'scan_to_pdf',
    'compress_pdf',
    'merge_pdf',
    'split_pdf',
    'image_to_pdf',
    'pdf_to_image',
    'convert_format',
    'resize_image',
    'compress_image',
    'stitch_images',
    'id_photo_maker',
    'batch_processing',
    'lock_pdf',
    'rotate_reorder',
    'upgrade_pro',
    'settings',
    'recent_files',
    'privacy_security',
  ];

  Directory(outputDir).createSync(recursive: true);

  for (var index = 0; index < toolIds.length; index++) {
    final col = index % columns;
    final row = index ~/ columns;

    final x = (col * cellW).round();
    final y = (row * cellH).round();
    final w = cellW.round();
    final h = cellH.round();

    // Crop illustration area (upper ~58% of card, centered).
    final cropX = x + (w * 0.08).round();
    final cropY = y + (h * 0.06).round();
    final cropW = (w * 0.84).round();
    final cropH = (h * 0.52).round();

    final cropped = copyCrop(
      sheet,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );

    final resized = copyResize(cropped, width: 512, height: 512);
    final outPath = '$outputDir/${toolIds[index]}.png';
    File(outPath).writeAsBytesSync(encodePng(resized));
    print('Wrote $outPath');
  }

  print('Done — ${toolIds.length} tool assets created in $outputDir/');
}
