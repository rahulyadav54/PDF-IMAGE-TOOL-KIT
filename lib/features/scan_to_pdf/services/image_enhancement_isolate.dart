import 'dart:typed_data';

import 'package:image/image.dart' as img;

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

Uint8List enhanceImageInIsolate(ImageEnhanceParams params) {
  final decoded = img.decodeImage(params.bytes);
  if (decoded == null) {
    return params.bytes;
  }

  final mode = modeFromKind(params.kind);
  var processed = mode == ScanEnhanceMode.original
      ? img.bakeOrientation(img.Image.from(decoded))
      : DocumentScanEnhancer.enhance(
          decoded,
          mode: mode,
          maxDimension: params.maxDimension,
          preview: params.preview,
        );

  processed = DocumentScanEnhancer.applyManualTweaks(
    processed,
    brightness: params.brightness,
    contrast: params.contrast,
  );

  if (mode != ScanEnhanceMode.original &&
      !DocumentScanEnhancer.isValidEnhancement(decoded, processed)) {
    processed = img.bakeOrientation(img.Image.from(decoded));
  }

  return Uint8List.fromList(
    img.encodeJpg(processed, quality: params.quality.clamp(70, 95)),
  );
}
