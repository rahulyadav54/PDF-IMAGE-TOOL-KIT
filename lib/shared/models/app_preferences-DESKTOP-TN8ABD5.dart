import '../../features/compress_pdf/models/compression_level.dart';
import '../../features/image_to_pdf/models/image_pdf_processing_options.dart';
import '../../features/pdf_to_image/models/image_export_format.dart';

/// User defaults persisted in Settings and applied to tool screens.
class AppPreferences {
  const AppPreferences({
    this.pdfQuality = ImagePdfQuality.high,
    this.compressionLevel = CompressionLevel.medium,
    this.exportFormat = ImageExportFormat.jpg,
    this.imageCompressQuality = 75,
  });

  final ImagePdfQuality pdfQuality;
  final CompressionLevel compressionLevel;
  final ImageExportFormat exportFormat;
  final int imageCompressQuality;

  String get pdfQualitySubtitle => switch (pdfQuality) {
        ImagePdfQuality.standard => 'Standard — smaller files',
        ImagePdfQuality.high => 'High — best clarity',
        ImagePdfQuality.maximum => 'Maximum — largest files',
      };

  String get compressionSubtitle => compressionLevel.description;

  String get exportFormatSubtitle =>
      '${exportFormat.label} — ${exportFormat == ImageExportFormat.png ? 'lossless' : 'smaller files'}';

  AppPreferences copyWith({
    ImagePdfQuality? pdfQuality,
    CompressionLevel? compressionLevel,
    ImageExportFormat? exportFormat,
    int? imageCompressQuality,
  }) {
    return AppPreferences(
      pdfQuality: pdfQuality ?? this.pdfQuality,
      compressionLevel: compressionLevel ?? this.compressionLevel,
      exportFormat: exportFormat ?? this.exportFormat,
      imageCompressQuality: imageCompressQuality ?? this.imageCompressQuality,
    );
  }

  /// Scan-to-PDF JPEG quality derived from PDF quality preset.
  int get scanJpegQuality => switch (pdfQuality) {
        ImagePdfQuality.standard => 82,
        ImagePdfQuality.high => 88,
        ImagePdfQuality.maximum => 92,
      };

  /// Scan-to-PDF max image width derived from PDF quality preset.
  int get scanMaxImageWidth => switch (pdfQuality) {
        ImagePdfQuality.standard => 1400,
        ImagePdfQuality.high => 1654,
        ImagePdfQuality.maximum => 2200,
      };
}
