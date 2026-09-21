import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_image_toolbox/features/scan_to_pdf/models/scan_enhance_kind.dart';
import 'package:pdf_image_toolbox/features/scan_to_pdf/services/image_enhancement_isolate.dart';

void main() {
  test('enhanceImageInIsolate applies magic color to document fixture', () {
    final source = img.Image(width: 120, height: 160);
    img.fill(source, color: img.ColorRgb8(225, 225, 225));
    img.fillRect(
      source,
      x1: 20,
      y1: 40,
      x2: 100,
      y2: 120,
      color: img.ColorRgb8(70, 70, 70),
    );

    final bytes = Uint8List.fromList(img.encodeJpg(source, quality: 90));
    final result = enhanceImageInIsolate(
      ImageEnhanceParams(
        bytes: bytes,
        kind: ScanEnhanceKind.magicColor,
        quality: 90,
        maxDimension: 720,
        preview: true,
      ),
    );

    expect(result.bytes, isNot(equals(bytes)));

    final decoded = img.decodeImage(result.bytes);
    expect(decoded, isNotNull);
    expect(decoded!.width, greaterThan(0));
  });

  test('enhanceImageInIsolate returns applied false for original mode', () {
    final source = img.Image(width: 80, height: 80, numChannels: 3);
    img.fill(source, color: img.ColorRgb8(200, 200, 200));
    final bytes = Uint8List.fromList(img.encodeJpg(source, quality: 90));

    final result = enhanceImageInIsolate(
      ImageEnhanceParams(
        bytes: bytes,
        kind: ScanEnhanceKind.original,
        quality: 90,
      ),
    );

    expect(result.applied, isFalse);
    expect(result.bytes.isNotEmpty, isTrue);
  });
}
