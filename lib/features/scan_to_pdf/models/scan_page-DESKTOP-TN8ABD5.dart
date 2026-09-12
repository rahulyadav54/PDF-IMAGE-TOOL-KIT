import 'scan_enhance_kind.dart';

/// A single scanned page with optional enhancement settings.
class ScanPage {
  const ScanPage({
    required this.id,
    required this.originalImagePath,
    required this.displayImagePath,
    this.enhanceKind = ScanEnhanceKind.original,
    this.brightness = 0,
    this.contrast = 0,
  });

  final String id;
  final String originalImagePath;
  final String displayImagePath;
  final ScanEnhanceKind enhanceKind;
  final double brightness;
  final double contrast;

  bool get grayscale => enhanceKind == ScanEnhanceKind.blackWhite;

  ScanPage copyWith({
    String? displayImagePath,
    ScanEnhanceKind? enhanceKind,
    double? brightness,
    double? contrast,
  }) {
    return ScanPage(
      id: id,
      originalImagePath: originalImagePath,
      displayImagePath: displayImagePath ?? this.displayImagePath,
      enhanceKind: enhanceKind ?? this.enhanceKind,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
    );
  }
}
