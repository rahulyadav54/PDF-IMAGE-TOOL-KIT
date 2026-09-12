import 'package:pdf/pdf.dart';

enum PdfPageSizeOption {
  a4('A4', 'Standard A4 paper'),
  letter('Letter', 'US Letter paper'),
  fitToImage('Fit to Image', 'Each page matches image size');

  const PdfPageSizeOption(this.label, this.description);

  final String label;
  final String description;
}

enum PdfPageOrientation {
  portrait('Portrait'),
  landscape('Landscape');

  const PdfPageOrientation(this.label);

  final String label;
}

/// Resolves page format based on user configuration.
class PdfPageConfig {
  const PdfPageConfig({
    this.pageSize = PdfPageSizeOption.a4,
    this.orientation = PdfPageOrientation.portrait,
  });

  final PdfPageSizeOption pageSize;
  final PdfPageOrientation orientation;

  PdfPageFormat resolveFormat({int? imageWidth, int? imageHeight}) {
    if (pageSize == PdfPageSizeOption.fitToImage) {
      if (imageWidth == null || imageHeight == null) {
        return PdfPageFormat.a4;
      }
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
}
