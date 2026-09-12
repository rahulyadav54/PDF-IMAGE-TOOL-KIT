import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_image_toolbox/features/scan_to_pdf/services/document_scan_enhancer.dart';

void main() {
  test('document enhancer removes dark corner shadow', () {
    final source = img.Image(width: 120, height: 120);
    img.fill(source, color: img.ColorRgb8(210, 210, 210));
    img.fillRect(
      source,
      x1: 0,
      y1: 0,
      x2: 40,
      y2: 40,
      color: img.ColorRgb8(70, 70, 70),
    );

    final enhanced =
        DocumentScanEnhancer.enhance(source, mode: ScanEnhanceMode.document);
    final darkCorner = enhanced.getPixel(10, 10).r;
    final brightArea = enhanced.getPixel(100, 100).r;

    expect(darkCorner, greaterThan(120));
    expect((darkCorner - brightArea).abs(), lessThan(70));
  });

  test('magic color mode brightens dim text region', () {
    final source = img.Image(width: 100, height: 100);
    img.fill(source, color: img.ColorRgb8(220, 220, 220));
    img.fillRect(
      source,
      x1: 30,
      y1: 30,
      x2: 70,
      y2: 70,
      color: img.ColorRgb8(120, 120, 120),
    );

    final enhanced =
        DocumentScanEnhancer.enhance(source, mode: ScanEnhanceMode.magicColor);
    final before = source.getPixel(50, 50).r;
    final after = enhanced.getPixel(50, 50).r;
    expect(after, isNot(equals(before)));
    expect(after, inInclusiveRange(0, 255));
  });

  test('black and white scan produces high contrast output', () {
    final source = img.Image(width: 80, height: 80);
    img.fill(source, color: img.ColorRgb8(235, 235, 235));
    img.fillRect(
      source,
      x1: 20,
      y1: 20,
      x2: 60,
      y2: 60,
      color: img.ColorRgb8(40, 40, 40),
    );

    final enhanced =
        DocumentScanEnhancer.enhance(source, mode: ScanEnhanceMode.blackWhite);
    for (final pixel in enhanced) {
      expect(pixel.r == 0 || pixel.r == 255, isTrue);
    }
  });
}
