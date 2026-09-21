import 'dart:math' as math;

import 'dart:typed_data';



import 'package:image/image.dart' as img;



import '../../../features/scan_to_pdf/services/document_image_analyzer.dart';

import 'content_bounds_detector.dart';

import 'document_boundary_detector.dart';

import 'document_frame_analyzer.dart';

import 'document_orientation_corrector.dart';

import 'document_processing_logger.dart';

import 'image_quality_validator.dart';

import 'perspective_corrector.dart';



class DocumentPipelineResult {

  const DocumentPipelineResult({

    required this.image,

    required this.rotationDegrees,

    required this.documentConfidence,

    required this.appliedPerspective,

    required this.appliedContentTrim,

    required this.documentLike,

    required this.corners,

    required this.needsManualAdjustment,

  });



  final img.Image image;

  final int rotationDegrees;

  final double documentConfidence;

  final bool appliedPerspective;

  final bool appliedContentTrim;

  final bool documentLike;

  final List<DocumentCorner> corners;

  final bool needsManualAdjustment;

}



/// Full document preparation: EXIF → detect → perspective → orientation → trim.

class DocumentImagePipeline {

  const DocumentImagePipeline._();



  static DocumentPipelineResult process(

    img.Image source, {

    bool enableDocumentGeometry = true,

    GeometryPolicy geometryPolicy = GeometryPolicy.autoDetect,

    List<DocumentCorner>? manualCorners,

  }) {

    final originalWidth = source.width;

    final originalHeight = source.height;



    var image = img.Image.from(source);
    final exifOrientation = image.exif.imageIfd.orientation ?? 1;
    final beforeExifWidth = image.width;
    final beforeExifHeight = image.height;

    image = img.bakeOrientation(image);

    DocumentProcessingLogger.logStageStats(stage: 'EXIF_NORMALIZED', image: image);



    final analysis = DocumentImageAnalyzer.analyze(image);

    final documentLike = _isDocumentLike(analysis);



    var rotationDegrees = 0;

    var documentConfidence = 0.0;

    var appliedPerspective = false;

    var appliedContentTrim = false;

    var corners = <DocumentCorner>[];

    var needsManualAdjustment = false;



    if (enableDocumentGeometry) {

      if (geometryPolicy == GeometryPolicy.preCropped) {

        corners = _fullFrameCorners(image.width, image.height);

        documentConfidence = 1.0;

      } else if (manualCorners != null && manualCorners.length == 4) {

        corners = DocumentBoundaryDetector.orderCorners(manualCorners);

        documentConfidence = 1.0;

        final corrected = PerspectiveCorrector.correct(image, corners);

        if (_isValidGeometryResult(image, corrected)) {

          image = corrected;

          appliedPerspective = true;

        }

      } else {

        final frame = DocumentFrameAnalyzer.analyze(image);



        if (frame.isAlreadyFramed) {

          corners = _fullFrameCorners(image.width, image.height);

          documentConfidence = 0.95;

        } else {

          final boundary = DocumentBoundaryDetector.detect(image);

          corners = boundary.corners;

          documentConfidence = boundary.confidence;



          final hasValidQuad = DocumentBoundaryDetector.isValidQuad(

            corners,

            image.width,

            image.height,

          );

          final tryPerspective = hasValidQuad &&

              boundary.confidence >= 0.42 &&

              frame.hasSignificantBackground;



          if (tryPerspective) {

            final corrected = PerspectiveCorrector.correct(image, corners);

            if (_isValidGeometryResult(image, corrected) &&

                !ImageQualityValidator.isMostlyBlank(corrected)) {

              final cropRatio =

                  (corrected.width * corrected.height) /

                  (image.width * image.height);

              if (cropRatio < 0.97) {

                image = corrected;

                appliedPerspective = true;

                DocumentProcessingLogger.logStageStats(
                  stage: 'AFTER_PERSPECTIVE',
                  image: image,
                );

              }

            }

          }



          if (!appliedPerspective &&

              frame.hasSignificantBackground &&

              !frame.isAlreadyFramed) {

            final beforeTrim = image;

            final contentBounds = ContentBoundsDetector.detect(beforeTrim);

            if (contentBounds.shouldTrim && contentBounds.confidence >= 0.2) {

              final trimmed =

                  ContentBoundsDetector.crop(beforeTrim, contentBounds);

              if (_isValidGeometryResult(beforeTrim, trimmed)) {

                image = trimmed;

                appliedContentTrim = true;

              }

            }

          }



          if (!appliedPerspective &&

              !appliedContentTrim &&

              frame.hasSignificantBackground) {

            needsManualAdjustment = true;

          }

        }

      }



      final beforeRotation = img.Image.from(image);

      rotationDegrees = DocumentOrientationCorrector.detectReadableRotation(

        image,

        sourceCorners: corners.length == 4 ? corners : null,

      );

      if (rotationDegrees != 0) {

        image = DocumentOrientationCorrector.applyRotation(image, rotationDegrees);

      }

      DocumentProcessingLogger.logStageStats(
        stage: 'AFTER_ORIENTATION',
        image: image,
      );

      if (ImageQualityValidator.hasProcessingArtifacts(beforeRotation, image)) {

        image = beforeRotation;

        rotationDegrees = 0;

      }

      // Reject black/crushed orientation results.
      if (ImageQualityValidator.isRadicallyDarkened(beforeRotation, image) ||
          ImageQualityValidator.isPolarityInverted(beforeRotation, image)) {
        image = beforeRotation;
        rotationDegrees = 0;
      }

    }



    DocumentProcessingLogger.logGeometry(

      originalWidth: originalWidth,

      originalHeight: originalHeight,

      exifOrientation: exifOrientation,

      beforeExifWidth: beforeExifWidth,

      beforeExifHeight: beforeExifHeight,

      corners: corners,

      perspectiveWidth: image.width,

      perspectiveHeight: image.height,

      rotationApplied: rotationDegrees,

      appliedPerspective: appliedPerspective,

      appliedContentTrim: appliedContentTrim,

      confidence: documentConfidence,

    );



    return DocumentPipelineResult(

      image: image,

      rotationDegrees: rotationDegrees,

      documentConfidence: documentConfidence,

      appliedPerspective: appliedPerspective,

      appliedContentTrim: appliedContentTrim,

      documentLike: documentLike,

      corners: corners,

      needsManualAdjustment: needsManualAdjustment && !appliedPerspective,

    );

  }



  static Uint8List encodeJpeg(img.Image image, int quality) {

    final rgb = image.numChannels >= 3

        ? image

        : image.convert(numChannels: 3);

    return Uint8List.fromList(

      img.encodeJpg(rgb, quality: quality.clamp(70, 95)),

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

    return analysis.edgeDensity >= 0.03;

  }



  static bool _isValidGeometryResult(img.Image before, img.Image after) {

    if (!ImageQualityValidator.isValidDimensions(after)) return false;

    if (after.width < 32 || after.height < 32) return false;



    final beforeArea = before.width * before.height;

    final afterArea = after.width * after.height;

    if (afterArea < beforeArea * 0.06) return false;

    if (afterArea > beforeArea * 1.05) return true;



    final beforeBrightness = _meanBrightness(before);

    final afterBrightness = _meanBrightness(after);

    if (afterBrightness > 0.99 || afterBrightness < 0.01) return false;

    if ((afterBrightness - beforeBrightness).abs() > 0.5) return false;



    return true;

  }



  static List<DocumentCorner> _fullFrameCorners(int width, int height) {

    return [

      DocumentCorner(0, 0),

      DocumentCorner(width.toDouble(), 0),

      DocumentCorner(width.toDouble(), height.toDouble()),

      DocumentCorner(0, height.toDouble()),

    ];

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


