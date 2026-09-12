import '../../scan_to_pdf/models/scan_enhance_kind.dart';

enum ImagePdfProcessingMode {
  original('Original Quality'),
  enhanceAll('Enhance All Images'),
  enhanceSelected('Enhance Selected Images');

  const ImagePdfProcessingMode(this.label);

  final String label;
}

enum ImagePdfQuality {
  standard('Standard', 1600, 82),
  high('High', 2200, 88),
  maximum('Maximum', 3000, 92);

  const ImagePdfQuality(this.label, this.maxDimension, this.jpegQuality);

  final String label;
  final int maxDimension;
  final int jpegQuality;
}

enum ImagePdfSizePreset {
  smaller('Smaller', 0.75),
  balanced('Balanced', 1.0),
  bestQuality('Best Quality', 1.15);

  const ImagePdfSizePreset(this.label, this.scale);

  final String label;
  final double scale;
}

class ImagePdfProcessingOptions {
  const ImagePdfProcessingOptions({
    this.processingMode = ImagePdfProcessingMode.original,
    this.quality = ImagePdfQuality.high,
    this.sizePreset = ImagePdfSizePreset.balanced,
    this.enhancementKind = ScanEnhanceKind.auto,
  });

  final ImagePdfProcessingMode processingMode;
  final ImagePdfQuality quality;
  final ImagePdfSizePreset sizePreset;
  final ScanEnhanceKind enhancementKind;

  int get effectiveMaxDimension =>
      (quality.maxDimension * sizePreset.scale).round().clamp(1200, 3200);

  int get effectiveJpegQuality =>
      (quality.jpegQuality * sizePreset.scale).round().clamp(70, 95);

  ImagePdfProcessingOptions copyWith({
    ImagePdfProcessingMode? processingMode,
    ImagePdfQuality? quality,
    ImagePdfSizePreset? sizePreset,
    ScanEnhanceKind? enhancementKind,
  }) {
    return ImagePdfProcessingOptions(
      processingMode: processingMode ?? this.processingMode,
      quality: quality ?? this.quality,
      sizePreset: sizePreset ?? this.sizePreset,
      enhancementKind: enhancementKind ?? this.enhancementKind,
    );
  }
}
