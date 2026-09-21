import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../shared/services/document_processing/document_processing_logger.dart';
import '../../../shared/services/document_processing/image_quality_validator.dart';
import '../models/scan_enhance_kind.dart';
import 'document_scan_enhancer.dart';

class ImageEnhanceParams {
  const ImageEnhanceParams({
    required this.bytes,
    required this.kind,
    this.brightness = 0,
    this.contrast = 0,
    this.quality = 88,
    this.maxDimension = 2200,
    this.preview = false,
  });

  final Uint8List bytes;
  final ScanEnhanceKind kind;
  final double brightness;
  final double contrast;
  final int quality;
  final int maxDimension;
  final bool preview;
}

class EnhanceIsolateResult {
  const EnhanceIsolateResult({
    required this.bytes,
    required this.applied,
  });

  final Uint8List bytes;
  final bool applied;
}

/// Runs off the UI thread for faster, non-blocking enhancement.
class OrientJpegParams {
  const OrientJpegParams({required this.bytes, required this.quality});

  final Uint8List bytes;
  final int quality;
}

Uint8List orientJpegInIsolate(OrientJpegParams params) {
  final decoded = img.decodeImage(params.bytes);
  if (decoded == null) return params.bytes;
  final oriented = img.bakeOrientation(decoded);
  return Uint8List.fromList(
    img.encodeJpg(oriented, quality: params.quality.clamp(70, 95)),
  );
}

EnhanceIsolateResult enhanceImageInIsolate(ImageEnhanceParams params) {
  final decoded = img.decodeImage(params.bytes);
  if (decoded == null) {
    return EnhanceIsolateResult(bytes: params.bytes, applied: false);
  }

  final mode = modeFromKind(params.kind);
  if (mode == ScanEnhanceMode.original) {
    final oriented = img.bakeOrientation(img.Image.from(decoded));
    return EnhanceIsolateResult(
      bytes: Uint8List.fromList(
        img.encodeJpg(oriented, quality: params.quality.clamp(70, 95)),
      ),
      applied: false,
    );
  }

  final oriented = img.bakeOrientation(img.Image.from(decoded));

  var processed = DocumentScanEnhancer.enhance(
    oriented,
    mode: mode,
    maxDimension: params.maxDimension,
    preview: params.preview,
  );

  processed = DocumentScanEnhancer.applyManualTweaks(
    processed,
    brightness: params.brightness,
    contrast: params.contrast,
  );

  final washedOut = DocumentScanEnhancer.isWashedOut(processed);
  final hasArtifacts = ImageQualityValidator.hasProcessingArtifacts(
    oriented,
    processed,
  );
  final blackened = ImageQualityValidator.isRadicallyDarkened(oriented, processed);
  final inverted = ImageQualityValidator.isPolarityInverted(oriented, processed);
  final valid = ImageQualityValidator.isValidDimensions(processed);
  final rejected = !valid || washedOut || hasArtifacts || blackened || inverted;
  final outputImage = rejected ? oriented : processed;
  final applied = !rejected && mode != ScanEnhanceMode.original;

  DocumentProcessingLogger.logStageStats(stage: 'ENHANCE_INPUT', image: oriented);
  DocumentProcessingLogger.logStageStats(
    stage: rejected ? 'ENHANCE_REJECTED' : 'ENHANCE_FINAL',
    image: outputImage,
  );
  DocumentProcessingLogger.logEnhancement(
    mode: mode.name,
    inputWidth: oriented.width,
    inputHeight: oriented.height,
    outputWidth: outputImage.width,
    outputHeight: outputImage.height,
    applied: applied,
    artifactDetected: rejected,
  );

  return EnhanceIsolateResult(
    bytes: Uint8List.fromList(
      img.encodeJpg(outputImage, quality: params.quality.clamp(70, 95)),
    ),
    applied: applied,
  );
}
