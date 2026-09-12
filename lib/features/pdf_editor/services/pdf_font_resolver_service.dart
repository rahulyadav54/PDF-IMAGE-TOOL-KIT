import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfFontResolution {
  const PdfFontResolution({
    required this.font,
    required this.preserved,
    this.notice,
  });

  final PdfFont font;
  final bool preserved;
  final String? notice;
}

/// Resolves PDF fonts for editing while preserving original appearance when possible.
class PdfFontResolverService {
  const PdfFontResolverService();

  PdfFontResolution resolve({
    required PdfDocument document,
    required String fontName,
    required double fontSize,
    required List<PdfFontStyle> styles,
  }) {
    final embedded = _tryEmbeddedFont(document, fontName, fontSize, styles);
    if (embedded != null) {
      return PdfFontResolution(font: embedded, preserved: true);
    }

    final standard = _tryStandardFont(fontName, fontSize, styles);
    if (standard != null) {
      final isExact = _isStandardNameMatch(fontName, standard);
      return PdfFontResolution(
        font: standard,
        preserved: isExact,
        notice: isExact
            ? null
            : 'The original font is unavailable. A similar font is being used.',
      );
    }

    return PdfFontResolution(
      font: PdfStandardFont(
        PdfFontFamily.helvetica,
        fontSize,
        multiStyle: styles,
      ),
      preserved: false,
      notice:
          'The original font is unavailable. A similar font is being used.',
    );
  }

  PdfFont resolveForNewText({
    required String fontFamily,
    required double fontSize,
    required List<PdfFontStyle> styles,
  }) {
    final family = _mapFamily(fontFamily);
    return PdfStandardFont(family, fontSize, multiStyle: styles);
  }

  PdfFont? _tryEmbeddedFont(
    PdfDocument document,
    String fontName,
    double fontSize,
    List<PdfFontStyle> styles,
  ) {
    final normalized = fontName.toLowerCase();
    if (normalized.contains('times') ||
        normalized.contains('helvetica') ||
        normalized.contains('courier') ||
        normalized.contains('symbol') ||
        normalized.contains('zapf') ||
        normalized.contains('arial')) {
      return null;
    }

    // Syncfusion Flutter PDF does not expose embedded font byte streams for reuse.
    // Custom/subset fonts fall back to metrically similar standard fonts.
    return null;
  }

  PdfStandardFont? _tryStandardFont(
    String fontName,
    double fontSize,
    List<PdfFontStyle> styles,
  ) {
    final family = _mapFamily(fontName);
    try {
      return PdfStandardFont(family, fontSize, multiStyle: styles);
    } catch (_) {
      return null;
    }
  }

  PdfFontFamily _mapFamily(String fontName) {
    final normalized = fontName.toLowerCase();
    if (normalized.contains('times')) return PdfFontFamily.timesRoman;
    if (normalized.contains('courier')) return PdfFontFamily.courier;
    if (normalized.contains('symbol')) return PdfFontFamily.symbol;
    if (normalized.contains('zapf')) return PdfFontFamily.zapfDingbats;
    return PdfFontFamily.helvetica;
  }

  bool _isStandardNameMatch(String fontName, PdfStandardFont font) {
    final normalized = fontName.toLowerCase();
    switch (font.fontFamily) {
      case PdfFontFamily.timesRoman:
        return normalized.contains('times');
      case PdfFontFamily.courier:
        return normalized.contains('courier');
      case PdfFontFamily.symbol:
        return normalized.contains('symbol');
      case PdfFontFamily.zapfDingbats:
        return normalized.contains('zapf');
      case PdfFontFamily.helvetica:
        return normalized.contains('helvetica') ||
            normalized.contains('arial') ||
            normalized.contains('sans');
    }
  }
}
