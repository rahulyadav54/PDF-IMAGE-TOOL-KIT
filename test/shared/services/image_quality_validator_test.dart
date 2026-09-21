import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_image_toolbox/shared/services/document_processing/image_quality_validator.dart';

void main() {
  group('ImageQualityValidator', () {
    test('detects blown highlight artifacts', () {
      final before = img.Image(width: 120, height: 120);
      img.fill(before, color: img.ColorRgb8(210, 210, 210));
      img.fillRect(
        before,
        x1: 20,
        y1: 20,
        x2: 100,
        y2: 100,
        color: img.ColorRgb8(40, 40, 40),
      );

      final after = img.Image.from(before);
      img.fillRect(
        after,
        x1: 30,
        y1: 30,
        x2: 90,
        y2: 90,
        color: img.ColorRgb8(255, 255, 255),
      );

      expect(
        ImageQualityValidator.hasProcessingArtifacts(before, after),
        isTrue,
      );
    });

    test('accepts mild enhancement without artifacts', () {
      final before = img.Image(width: 100, height: 100);
      img.fill(before, color: img.ColorRgb8(200, 200, 200));
      final after = img.Image.from(before);
      for (var y = 0; y < after.height; y++) {
        for (var x = 0; x < after.width; x++) {
          final p = before.getPixel(x, y);
          after.setPixelRgba(
            x,
            y,
            (p.r + 8).clamp(0, 255),
            (p.g + 8).clamp(0, 255),
            (p.b + 8).clamp(0, 255),
            255,
          );
        }
      }

      expect(
        ImageQualityValidator.hasProcessingArtifacts(before, after),
        isFalse,
      );
    });

    test('detects radical darkening of light paper', () {
      final before = img.Image(width: 100, height: 100);
      img.fill(before, color: img.ColorRgb8(200, 200, 200));
      final after = img.Image(width: 100, height: 100);
      img.fill(after, color: img.ColorRgb8(10, 10, 10));

      expect(ImageQualityValidator.isRadicallyDarkened(before, after), isTrue);
      expect(ImageQualityValidator.hasProcessingArtifacts(before, after), isTrue);
    });
  });
}
