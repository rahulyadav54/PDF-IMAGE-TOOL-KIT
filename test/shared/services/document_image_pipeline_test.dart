import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_image_toolbox/shared/services/document_processing/content_bounds_detector.dart';
import 'package:pdf_image_toolbox/shared/services/document_processing/document_image_pipeline.dart';
import 'package:pdf_image_toolbox/shared/services/document_processing/text_orientation_detector.dart';

void main() {
  group('TextOrientationDetector', () {
    test('keeps upright text unchanged', () {
      final image = img.Image(width: 400, height: 300);
      for (var y = 40; y < 260; y += 18) {
        for (var x = 30; x < 360; x += 12) {
          image.setPixelRgba(x, y, 20, 20, 20, 255);
        }
      }
      final rotation = TextOrientationDetector.detectCorrectionDegrees(
        image,
        documentLike: true,
      );
      expect(rotation, 0);
    });
  });

  group('ContentBoundsDetector', () {
    test('trims uniform white borders', () {
      final image = img.Image(width: 500, height: 400, numChannels: 3);
      img.fill(image, color: img.ColorRgb8(250, 250, 250));
      img.fillRect(
        image,
        x1: 120,
        y1: 80,
        x2: 380,
        y2: 320,
        color: img.ColorRgb8(30, 30, 30),
      );

      final bounds = ContentBoundsDetector.detect(image);
      expect(bounds.shouldTrim, isTrue);
      expect(bounds.width, lessThan(image.width));
      expect(bounds.height, lessThan(image.height));
    });
  });

  group('DocumentImagePipeline', () {
    test('normalizes EXIF-oriented dimensions', () {
      final image = img.Image(width: 300, height: 400, numChannels: 3);
      img.fill(image, color: img.ColorRgb8(200, 200, 200));
      final result = DocumentImagePipeline.process(image);
      expect(result.image.width, greaterThan(0));
      expect(result.image.height, greaterThan(0));
    });
  });
}
