import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_image_toolbox/shared/services/document_processing/document_boundary_detector.dart';
import 'package:pdf_image_toolbox/shared/services/document_processing/document_frame_analyzer.dart';
import 'package:pdf_image_toolbox/shared/services/document_processing/document_image_pipeline.dart';
import 'package:pdf_image_toolbox/shared/services/document_processing/perspective_corrector.dart';

void main() {
  img.Image _deskPhotoDocument() {
    final image = img.Image(width: 900, height: 700, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(55, 58, 62));

    final corners = [
      DocumentCorner(180, 110),
      DocumentCorner(720, 130),
      DocumentCorner(760, 590),
      DocumentCorner(140, 610),
    ];

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        if (_pointInQuad(x.toDouble(), y.toDouble(), corners)) {
          final noise = ((x + y) % 17) * 2;
          image.setPixelRgba(x, y, 235 + noise, 235 + noise, 230 + noise, 255);
        }
      }
    }

    for (var y = 120; y < 580; y += 22) {
      for (var x = 220; x < 680; x += 10) {
        if (_pointInQuad(x.toDouble(), y.toDouble(), corners)) {
          image.setPixelRgba(x, y, 25, 25, 25, 255);
        }
      }
    }

    return image;
  }

  test('detects document on desk background', () {
    final image = _deskPhotoDocument();
    final result = DocumentBoundaryDetector.detect(image);

    expect(result.corners.length, 4);
    expect(result.confidence, greaterThan(0.2));
    expect(DocumentBoundaryDetector.isValidQuad(
      result.corners,
      image.width,
      image.height,
    ), isTrue);
  });

  test('perspective correction crops desk background', () {
    final image = _deskPhotoDocument();
    final boundary = DocumentBoundaryDetector.detect(image);
    expect(boundary.corners.length, 4);

    final padded = DocumentBoundaryDetector.expandCorners(
      boundary.corners,
      image.width,
      image.height,
    );
    final corrected = PerspectiveCorrector.correct(image, padded);

    final areaBefore = image.width * image.height;
    final areaAfter = corrected.width * corrected.height;
    expect(areaAfter, lessThan(areaBefore * 0.75));
    expect(corrected.width, greaterThan(200));
    expect(corrected.height, greaterThan(200));
  });

  test('pipeline trims document photo', () {
    final image = _deskPhotoDocument();
    final result = DocumentImagePipeline.process(
      image,
      geometryPolicy: GeometryPolicy.autoDetect,
    );

    final areaBefore = image.width * image.height;
    final areaAfter = result.image.width * result.image.height;
    expect(areaAfter, lessThan(areaBefore * 0.8));
    expect(result.appliedPerspective || result.appliedContentTrim, isTrue);
  });
}

bool _pointInQuad(double x, double y, List<DocumentCorner> corners) {
  var inside = false;
  for (var i = 0, j = corners.length - 1; i < corners.length; j = i++) {
    final xi = corners[i].x;
    final yi = corners[i].y;
    final xj = corners[j].x;
    final yj = corners[j].y;
    final intersect = ((yi > y) != (yj > y)) &&
        (x < (xj - xi) * (y - yi) / (yj - yi + 1e-6) + xi);
    if (intersect) inside = !inside;
  }
  return inside;
}
