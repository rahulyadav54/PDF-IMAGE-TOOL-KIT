import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'document_boundary_detector.dart';
import 'image_quality_validator.dart';

/// Debug logging for document scan geometry and enhancement.
class DocumentProcessingLogger {
  const DocumentProcessingLogger._();

  static void logGeometry({
    required int originalWidth,
    required int originalHeight,
    int exifOrientation = 1,
    int? beforeExifWidth,
    int? beforeExifHeight,
    required List<DocumentCorner> corners,
    required int perspectiveWidth,
    required int perspectiveHeight,
    required int rotationApplied,
    required bool appliedPerspective,
    required bool appliedContentTrim,
    required double confidence,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[DocScan] original=${originalWidth}x$originalHeight '
      'exif=$exifOrientation '
      'beforeExif=${beforeExifWidth ?? originalWidth}x${beforeExifHeight ?? originalHeight} '
      'corners=${_cornersString(corners)} '
      'perspective=${perspectiveWidth}x$perspectiveHeight '
      'rotation=$rotationApplied° '
      'perspective=$appliedPerspective trim=$appliedContentTrim '
      'confidence=${confidence.toStringAsFixed(2)}',
    );
  }

  static void logEnhancement({
    required String mode,
    required int inputWidth,
    required int inputHeight,
    required int outputWidth,
    required int outputHeight,
    required bool applied,
    required bool artifactDetected,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[DocScan] enhance mode=$mode '
      'in=${inputWidth}x$inputHeight '
      'out=${outputWidth}x$outputHeight '
      'applied=$applied artifact=$artifactDetected',
    );
  }

  static void logStageStats({
    required String stage,
    required img.Image image,
  }) {
    if (!kDebugMode) return;
    final s = ImageQualityValidator.computeStats(image);
    debugPrint(
      '[DocScan] stage=$stage '
      'width=${s.width} height=${s.height} channels=${s.channels} '
      'min=${s.min.toStringAsFixed(1)} max=${s.max.toStringAsFixed(1)} '
      'mean=${s.mean.toStringAsFixed(1)} '
      'black=${(s.blackPixelPercentage * 100).toStringAsFixed(1)}% '
      'white=${(s.whitePixelPercentage * 100).toStringAsFixed(1)}%',
    );
  }

  static String _cornersString(List<DocumentCorner> corners) {
    if (corners.length != 4) return '[]';
    return corners
        .map((c) => '(${c.x.round()},${c.y.round()})')
        .join('→');
  }
}
