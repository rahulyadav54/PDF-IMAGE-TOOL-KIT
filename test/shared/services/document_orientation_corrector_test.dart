import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_image_toolbox/shared/services/document_processing/document_boundary_detector.dart';
import 'package:pdf_image_toolbox/shared/services/document_processing/document_orientation_corrector.dart';

void main() {
  group('DocumentOrientationCorrector', () {
    img.Image _textLines({required int width, required int height}) {
      final image = img.Image(width: width, height: height);
      img.fill(image, color: img.ColorRgb8(235, 235, 235));
      for (var y = 30; y < height - 30; y += 16) {
        for (var x = 24; x < width - 24; x++) {
          image.setPixelRgba(x, y, 25, 25, 25, 255);
        }
      }
      return image;
    }

    test('keeps upright portrait document unchanged', () {
      final image = _textLines(width: 320, height: 480);
      final rotation = DocumentOrientationCorrector.detectReadableRotation(image);
      expect(rotation, 0);
    });

    test('rotates sideways portrait capture to readable portrait', () {
      final sideways = img.copyRotate(
        _textLines(width: 320, height: 480),
        angle: 90,
      );
      final rotation =
          DocumentOrientationCorrector.detectReadableRotation(sideways);
      expect(rotation, anyOf(90, 270));
      final corrected =
          DocumentOrientationCorrector.applyRotation(sideways, rotation);
      expect(corrected.height, greaterThan(corrected.width));
    });

    test('preserves physically landscape document', () {
      final landscape = _textLines(width: 520, height: 360);
      final corners = [
        DocumentCorner(0, 0),
        DocumentCorner(520, 0),
        DocumentCorner(520, 360),
        DocumentCorner(0, 360),
      ];
      final rotation = DocumentOrientationCorrector.detectReadableRotation(
        landscape,
        sourceCorners: corners,
      );
      expect(rotation, 0);
      expect(landscape.width, greaterThan(landscape.height));
    });
  });
}
