import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../features/image_to_pdf/models/pdf_page_config.dart';

/// Resolves smart PDF page format and professional margins per image.
class PdfPageLayout {
  const PdfPageLayout({
    required this.format,
    required this.margins,
  });

  final PdfPageFormat format;
  final pw.EdgeInsets margins;

  static const double marginFraction = 0.04;
  static const double minMarginPoints = 12;
  static const double maxMarginPoints = 36;

  static PdfPageLayout resolve({
    required PdfPageConfig config,
    required int imageWidth,
    required int imageHeight,
  }) {
    final format = _resolveFormat(
      config: config,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );

    final margins = config.pageSize == PdfPageSizeOption.fitToImage
        ? pw.EdgeInsets.zero
        : _computeMargins(format);

    return PdfPageLayout(format: format, margins: margins);
  }

  static PdfPageFormat _resolveFormat({
    required PdfPageConfig config,
    required int imageWidth,
    required int imageHeight,
  }) {
    if (imageWidth <= 0 || imageHeight <= 0) {
      return PdfPageFormat.a4;
    }

    if (config.pageSize == PdfPageSizeOption.fitToImage) {
      final width = imageWidth * PdfPageFormat.inch / 72;
      final height = imageHeight * PdfPageFormat.inch / 72;
      return PdfPageFormat(width, height);
    }

    if (config.pageSize == PdfPageSizeOption.auto) {
      return _autoFormat(imageWidth, imageHeight);
    }

    PdfPageFormat format;
    switch (config.pageSize) {
      case PdfPageSizeOption.a4:
        format = PdfPageFormat.a4;
      case PdfPageSizeOption.letter:
        format = PdfPageFormat.letter;
      case PdfPageSizeOption.auto:
      case PdfPageSizeOption.fitToImage:
        format = PdfPageFormat.a4;
    }

    final landscape = _shouldUseLandscape(
      config: config,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
    return landscape ? format.landscape : format;
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
    return _closestFitFormat(
      imageWidth,
      imageHeight,
      [a4Portrait, a4Landscape, PdfPageFormat.letter, PdfPageFormat.letter.landscape],
    );
  }

  static PdfPageFormat _bestPaperFormat(double aspect, {required bool landscape}) {
    final a4 = landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;
    final letter = landscape ? PdfPageFormat.letter.landscape : PdfPageFormat.letter;
    final a4Aspect = a4.width / a4.height;
    final letterAspect = letter.width / letter.height;
    final a4Delta = (aspect - a4Aspect).abs();
    final letterDelta = (aspect - letterAspect).abs();
    return a4Delta <= letterDelta ? a4 : letter;
  }

  static PdfPageFormat _closestFitFormat(
    int imageWidth,
    int imageHeight,
    List<PdfPageFormat> candidates,
  ) {
    final imageAspect = imageWidth / imageHeight;
    PdfPageFormat? best;
    var bestDelta = double.infinity;

    for (final format in candidates) {
      final pageAspect = format.width / format.height;
      final delta = (imageAspect - pageAspect).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        best = format;
      }
    }

    return best ?? PdfPageFormat.a4;
  }

  static bool _shouldUseLandscape({
    required PdfPageConfig config,
    required int imageWidth,
    required int imageHeight,
  }) {
    if (config.orientation == PdfPageOrientation.landscape) return true;
    if (config.orientation == PdfPageOrientation.portrait) return false;
    return imageWidth > imageHeight * 1.05;
  }

  static pw.EdgeInsets _computeMargins(PdfPageFormat format) {
    final margin = (format.width * marginFraction)
        .clamp(minMarginPoints, maxMarginPoints)
        .toDouble();
    return pw.EdgeInsets.all(margin);
  }
}
