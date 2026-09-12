import 'package:pdf/pdf.dart';

enum PdfPageSizeOption {
  auto('Auto', 'Best page size and orientation for each image'),
  a4('A4', 'Standard A4 paper'),
  letter('Letter', 'US Letter paper'),
  fitToImage('Fit to Image', 'Each page matches image size');

  const PdfPageSizeOption(this.label, this.description);

  final String label;
  final String description;
}

enum PdfPageOrientation {
  auto('Auto'),
  portrait('Portrait'),
  landscape('Landscape');

  const PdfPageOrientation(this.label);

  final String label;
}

/// Resolves page format based on user configuration.
class PdfPageConfig {
  const PdfPageConfig({
    this.pageSize = PdfPageSizeOption.auto,
    this.orientation = PdfPageOrientation.auto,
  });

  final PdfPageSizeOption pageSize;
  final PdfPageOrientation orientation;

  PdfPageFormat resolveFormat({int? imageWidth, int? imageHeight}) {
    if (imageWidth != null &&
        imageHeight != null &&
        imageWidth > 0 &&
        imageHeight > 0) {
      if (pageSize == PdfPageSizeOption.auto) {
        return _autoFormat(imageWidth, imageHeight);
      }

      if (pageSize == PdfPageSizeOption.fitToImage) {
        final width = imageWidth * PdfPageFormat.inch / 72;
        final height = imageHeight * PdfPageFormat.inch / 72;
        return PdfPageFormat(width, height);
      }

      PdfPageFormat format;
      switch (pageSize) {
        case PdfPageSizeOption.a4:
          format = PdfPageFormat.a4;
        case PdfPageSizeOption.letter:
          format = PdfPageFormat.letter;
        case PdfPageSizeOption.auto:
        case PdfPageSizeOption.fitToImage:
          format = PdfPageFormat.a4;
      }

      final landscape = orientation == PdfPageOrientation.landscape ||
          (orientation == PdfPageOrientation.auto && imageWidth > imageHeight * 1.05);
      return landscape ? format.landscape : format;
    }

    if (pageSize == PdfPageSizeOption.fitToImage) {
      return PdfPageFormat.a4;
    }

    PdfPageFormat format;
    switch (pageSize) {
      case PdfPageSizeOption.a4:
        format = PdfPageFormat.a4;
      case PdfPageSizeOption.letter:
        format = PdfPageFormat.letter;
      case PdfPageSizeOption.auto:
        format = PdfPageFormat.a4;
      case PdfPageSizeOption.fitToImage:
        format = PdfPageFormat.a4;
    }

    if (orientation == PdfPageOrientation.landscape) {
      return format.landscape;
    }
    return format;
  }

  PdfPageConfig copyWith({
    PdfPageSizeOption? pageSize,
    PdfPageOrientation? orientation,
  }) {
    return PdfPageConfig(
      pageSize: pageSize ?? this.pageSize,
      orientation: orientation ?? this.orientation,
    );
  }

  static PdfPageFormat _autoFormat(int imageWidth, int imageHeight) {
    final aspect = imageWidth / imageHeight;
    if (aspect >= 1.12) {
      return _bestPaperFormat(aspect, landscape: true);
    }
    if (aspect <= 0.88) {
      return _bestPaperFormat(aspect, landscape: false);
    }
    final a4Portrait = PdfPageFormat.a4;
    final a4Landscape = PdfPageFormat.a4.landscape;
    final imageAspect = aspect;
    final portraitDelta = (imageAspect - (a4Portrait.width / a4Portrait.height)).abs();
    final landscapeDelta = (imageAspect - (a4Landscape.width / a4Landscape.height)).abs();
    return portraitDelta <= landscapeDelta ? a4Portrait : a4Landscape;
  }

  static PdfPageFormat _bestPaperFormat(double aspect, {required bool landscape}) {
    final a4 = landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;
    final letter = landscape ? PdfPageFormat.letter.landscape : PdfPageFormat.letter;
    final a4Delta = (aspect - (a4.width / a4.height)).abs();
    final letterDelta = (aspect - (letter.width / letter.height)).abs();
    return a4Delta <= letterDelta ? a4 : letter;
  }
}
