import '../../../shared/services/document_processing/document_boundary_detector.dart';
import 'scan_enhance_kind.dart';

/// A single scanned page with raw capture, geometry-corrected, and display paths.
class ScanPage {
  const ScanPage({
    required this.id,
    required this.rawCapturePath,
    required this.originalImagePath,
    required this.displayImagePath,
    this.enhanceKind = ScanEnhanceKind.auto,
    this.brightness = 0,
    this.contrast = 0,
    this.geometryApplied = false,
    this.geometryConfidence = 0,
    this.needsCornerAdjustment = false,
    this.corners = const [],
  });

  final String id;
  /// Immutable camera/file capture — never modified.
  final String rawCapturePath;
  /// Geometry-corrected image used as the enhancement source.
  final String originalImagePath;
  /// Currently displayed image (usually enhanced).
  final String displayImagePath;
  final ScanEnhanceKind enhanceKind;
  final double brightness;
  final double contrast;
  final bool geometryApplied;
  final double geometryConfidence;
  final bool needsCornerAdjustment;
  final List<DocumentCorner> corners;

  bool get grayscale => enhanceKind == ScanEnhanceKind.blackWhite;

  ScanPage copyWith({
    String? originalImagePath,
    String? displayImagePath,
    ScanEnhanceKind? enhanceKind,
    double? brightness,
    double? contrast,
    bool? geometryApplied,
    double? geometryConfidence,
    bool? needsCornerAdjustment,
    List<DocumentCorner>? corners,
  }) {
    return ScanPage(
      id: id,
      rawCapturePath: rawCapturePath,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      displayImagePath: displayImagePath ?? this.displayImagePath,
      enhanceKind: enhanceKind ?? this.enhanceKind,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      geometryApplied: geometryApplied ?? this.geometryApplied,
      geometryConfidence: geometryConfidence ?? this.geometryConfidence,
      needsCornerAdjustment:
          needsCornerAdjustment ?? this.needsCornerAdjustment,
      corners: corners ?? this.corners,
    );
  }
}
