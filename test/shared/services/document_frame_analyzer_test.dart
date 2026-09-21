import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_image_toolbox/shared/services/document_processing/document_frame_analyzer.dart';
import 'package:pdf_image_toolbox/shared/services/document_processing/document_image_pipeline.dart';

void main() {
  test('detects tight scanner crop as already framed', () {
    final image = img.Image(width: 800, height: 1000, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(240, 238, 232));
    for (var y = 80; y < 920; y += 20) {
      for (var x = 60; x < 740; x += 12) {
        image.setPixelRgba(x, y, 30, 30, 30, 255);
      }
    }

    final frame = DocumentFrameAnalyzer.analyze(image);
    expect(frame.isAlreadyFramed, isTrue);
  });

  test('preCropped policy does not shrink scanner-like image', () {
    final image = img.Image(width: 800, height: 1000, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(240, 238, 232));
    for (var y = 80; y < 920; y += 20) {
      for (var x = 60; x < 740; x += 12) {
        image.setPixelRgba(x, y, 30, 30, 30, 255);
      }
    }

    final result = DocumentImagePipeline.process(
      image,
      geometryPolicy: GeometryPolicy.preCropped,
    );

    expect(result.appliedPerspective, isFalse);
    expect(result.appliedContentTrim, isFalse);
    expect(result.image.width, image.width);
    expect(result.image.height, image.height);
  });
}
