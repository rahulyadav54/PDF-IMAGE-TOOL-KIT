import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../features/scan_to_pdf/services/document_image_analyzer.dart';
import 'content_bounds_detector.dart';
import 'document_boundary_detector.dart';
import 'perspective_corrector.dart';
import 'text_orientation_detector.dart';

class DocumentPipelineResult {
  const DocumentPipelineResult({
    required this.image,
    required this.rotationDegrees,
    required this.documentConfidence,
    required this.appliedPerspective,
    required this.appliedContentTrim,
    required this.documentLike,
  });

  final img.Image image;
  final int rotationDegrees;
  final double documentConfidence;
  final bool appliedPerspective;
  final bool appliedContentTrim;
  final bool documentLike;
}

/// Full document preparation pipeline for PDF export.
class DocumentImagePipeline {
  const DocumentImagePipeline._();

  static DocumentPipelineResult process(
    img.Image source, {
    bool enableDocumentGeometry = true,
  }) {
    var image = img.Image.from(source);
    image = img.bakeOrientation(image);

    final analysis = DocumentImageAnalyzer.analyze(image);
    final documentLike = _isDocumentLike(analysis);

    var rotationDegrees = 0;
    if (documentLike) {
      rotationDegrees = TextOrientationDetector.detectCorrectionDegrees(
        image,
        documentLike: true,
      );
      if (rotationDegrees != 0) {
        image = TextOrientationDetector.applyRotation(image, rotationDegrees);
      }
    }

    var documentConfidence = 0.0;
    var appliedPerspective = false;
    var appliedContentTrim = false;

    if (enableDocumentGeometry) {
      final boundary = DocumentBoundaryDetector.detect(image);
      documentConfidence = boundary.confidence;

      if (boundary.isReliable) {
        final corrected = PerspectiveCorrector.correct(image, boundary.corners);
        if (_isValidGeometryResult(image, corrected)) {
          image = corrected;
          appliedPerspective = true;
        }
      } else {
        final contentBounds = ContentBoundsDetector.detect(image);
        if (contentBounds.shouldTrim && contentBounds.confidence >= 0.2) {
          final trimmed = ContentBoundsDetector.crop(image, contentBounds);
          if (_isValidGeometryResult(image, trimmed)) {
            image = trimmed;
            appliedContentTrim = true;
          }
        }
      }
    }

    return DocumentPipelineResult(
      image: image,
      rotationDegrees: rotationDegrees,
      documentConfidence: documentConfidence,
      appliedPerspective: appliedPerspective,
      appliedContentTrim: appliedContentTrim,
      documentLike: documentLike,
    );
  }

  static Uint8List encodeJpeg(img.Image image, int quality) {
    return Uint8List.fromList(
      img.encodeJpg(image, quality: quality.clamp(70, 95)),
    );
  }

  static img.Image resizeForOutput(img.Image image, int maxWidth) {
    if (image.width <= maxWidth) return image;
    return img.copyResize(image, width: maxWidth);
  }

  static bool _isDocumentLike(DocumentImageAnalysis analysis) {
    if (analysis.contentType == DocumentContentType.photo &&
        analysis.edgeDensity < 0.05) {
      return false;
    }
    return analysis.edgeDensity >= 0.035;
  }

  static bool _isValidGeometryResult(img.Image before, img.Image after) {
    if (after.width < 32 || after.height < 32) return false;

    final beforeArea = before.width * before.height;
    final afterArea = after.width * after.height;
    if (afterArea < beforeArea * 0.08) return false;
    if (afterArea > beforeArea * 1.05) {
      return true;
    }

    final beforeBrightness = _meanBrightness(before);
    final afterBrightness = _meanBrightness(after);
    if (afterBrightness > 0.985 || afterBrightness < 0.01) return false;
    if ((afterBrightness - beforeBrightness).abs() > 0.45) return false;

    return true;
  }

  static double _meanBrightness(img.Image image) {
    final sample = img.copyResize(image, width: 120);
    var sum = 0.0;
    for (final pixel in sample) {
      sum += (pixel.r + pixel.g + pixel.b) / (3 * 255);
    }
    return sum / math.max(1, sample.width * sample.height);
  }
}
