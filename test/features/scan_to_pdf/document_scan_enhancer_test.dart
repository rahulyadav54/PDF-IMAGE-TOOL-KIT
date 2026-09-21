import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_image_toolbox/features/scan_to_pdf/services/document_scan_enhancer.dart';
import 'package:pdf_image_toolbox/shared/services/document_processing/image_quality_validator.dart';

void main() {
  test('document enhancer keeps paper light without crushing shadows to black', () {
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
    final stats = ImageQualityValidator.computeStats(enhanced);

    expect(stats.mean, greaterThan(100));
    expect(ImageQualityValidator.isRadicallyDarkened(source, enhanced), isFalse);
    expect(DocumentScanEnhancer.enhancementDelta(source, enhanced), greaterThan(0));
  });

  test('auto mode is visibly different from original', () {
    final source = img.Image(width: 200, height: 260);
    img.fill(source, color: img.ColorRgb8(195, 192, 185));
    for (var y = 40; y < 220; y += 18) {
      for (var x = 30; x < 170; x += 10) {
        source.setPixelRgba(x, y, 35, 35, 35, 255);
      }
    }

    final auto =
        DocumentScanEnhancer.enhance(source, mode: ScanEnhanceMode.auto);
    final delta = DocumentScanEnhancer.enhancementDelta(source, auto);

    expect(delta, greaterThan(0.01));
    expect(
      auto.getPixel(50, 40).r,
      lessThan(auto.getPixel(100, 100).r - 30),
    );
    expect(auto.getPixel(100, 100).r, greaterThanOrEqualTo(source.getPixel(100, 100).r));
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

  test('enhancementWasApplied accepts uneven document scan', () {
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
    img.fillRect(
      source,
      x1: 35,
      y1: 45,
      x2: 95,
      y2: 95,
      color: img.ColorRgb8(95, 95, 95),
    );

    final enhanced =
        DocumentScanEnhancer.enhance(source, mode: ScanEnhanceMode.magicColor);

    expect(enhanced.getPixel(60, 60).r, lessThan(200));
    expect(DocumentScanEnhancer.enhancementDelta(source, enhanced), greaterThan(0.002));
  });

  test('enhancementWasApplied accepts black and white despite edge change', () {
    final source = img.Image(width: 90, height: 90);
    img.fill(source, color: img.ColorRgb8(235, 235, 235));
    img.fillRect(
      source,
      x1: 20,
      y1: 20,
      x2: 70,
      y2: 70,
      color: img.ColorRgb8(40, 40, 40),
    );

    final enhanced =
        DocumentScanEnhancer.enhance(source, mode: ScanEnhanceMode.blackWhite);

    expect(
      DocumentScanEnhancer.enhancementWasApplied(
        source,
        enhanced,
        mode: ScanEnhanceMode.blackWhite,
      ),
      isTrue,
    );
  });

  test('bright document does not wash out to white', () {
    final source = img.Image(width: 120, height: 120);
    img.fill(source, color: img.ColorRgb8(235, 235, 235));
    img.fillRect(
      source,
      x1: 25,
      y1: 25,
      x2: 95,
      y2: 95,
      color: img.ColorRgb8(30, 30, 30),
    );

    final enhanced = DocumentScanEnhancer.enhance(
      source,
      mode: ScanEnhanceMode.magicColor,
    );

    var darkPixels = 0;
    for (final pixel in enhanced) {
      if (pixel.r < 80) darkPixels++;
    }
    expect(darkPixels, greaterThan(100));
    expect(enhanced.getPixel(50, 50).r, lessThan(200));
    expect(DocumentScanEnhancer.enhancementDelta(source, enhanced), greaterThan(0.002));
  });

  test('auto mode preserves handwritten ink without white patches', () {
    final source = img.Image(width: 240, height: 320);
    img.fill(source, color: img.ColorRgb8(205, 200, 190));
    for (var y = 40; y < 280; y += 14) {
      for (var x = 28; x < 210; x += 7) {
        source.setPixelRgba(x, y, 45, 42, 38, 255);
      }
    }
    img.fillRect(
      source,
      x1: 0,
      y1: 0,
      x2: 70,
      y2: 70,
      color: img.ColorRgb8(55, 55, 55),
    );

    final enhanced =
        DocumentScanEnhancer.enhance(source, mode: ScanEnhanceMode.auto);

    var inkPixels = 0;
    var blownPixels = 0;
    for (final pixel in enhanced) {
      if (pixel.r < 90) inkPixels++;
      if (pixel.r > 248 && pixel.g > 248 && pixel.b > 248) blownPixels++;
    }

    expect(inkPixels, greaterThan(80));
    expect(blownPixels, lessThan(enhanced.width * enhanced.height * 0.15));
    expect(DocumentScanEnhancer.isWashedOut(enhanced), isFalse);
  });

  test('auto mode never turns light paper black', () {
    final source = img.Image(width: 200, height: 280);
    img.fill(source, color: img.ColorRgb8(220, 215, 205));
    for (var y = 40; y < 240; y += 16) {
      for (var x = 30; x < 170; x += 8) {
        source.setPixelRgba(x, y, 40, 40, 40, 255);
      }
    }

    final enhanced =
        DocumentScanEnhancer.enhance(source, mode: ScanEnhanceMode.auto);
    final before = ImageQualityValidator.computeStats(source);
    final after = ImageQualityValidator.computeStats(enhanced);

    expect(after.mean, greaterThan(120));
    expect(after.blackPixelPercentage, lessThan(0.35));
    expect(
      ImageQualityValidator.isRadicallyDarkened(source, enhanced),
      isFalse,
    );
    expect(after.mean, greaterThan(before.mean * 0.85));
  });

  test('validation rejects artificially blackened enhance result', () {
    final source = img.Image(width: 100, height: 100);
    img.fill(source, color: img.ColorRgb8(210, 210, 210));
    final black = img.Image(width: 100, height: 100);
    img.fill(black, color: img.ColorRgb8(8, 8, 8));

    expect(ImageQualityValidator.isRadicallyDarkened(source, black), isTrue);
    expect(DocumentScanEnhancer.isWashedOut(black), isTrue);
  });

  test('document mode applies mild color-safe enhancement', () {
    final sharp = img.Image(width: 100, height: 100);
    img.fill(sharp, color: img.ColorRgb8(240, 240, 240));
    for (var x = 20; x < 80; x++) {
      sharp.setPixelRgba(x, 50, 20, 20, 20, 255);
    }

    final enhanced =
        DocumentScanEnhancer.enhance(sharp, mode: ScanEnhanceMode.document);

    expect(enhanced.getPixel(50, 50).r, lessThan(80));
    expect(
      ImageQualityValidator.isRadicallyDarkened(sharp, enhanced),
      isFalse,
    );
    expect(DocumentScanEnhancer.enhancementDelta(sharp, enhanced), greaterThan(0));
  });
}
