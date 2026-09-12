import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'pdf_font_resolver_service.dart';

/// Caches font resolution results per document to avoid repeated lookups.
class PdfDocumentFontCache {
  PdfDocumentFontCache(this._document) : _resolver = const PdfFontResolverService();

  final PdfDocument _document;
  final PdfFontResolverService _resolver;
  final Map<String, PdfFontResolution> _cache = {};

  PdfFontResolution resolve({
    required String fontName,
    required double fontSize,
    required List<PdfFontStyle> styles,
  }) {
    final key =
        '${fontName.toLowerCase()}|${fontSize.toStringAsFixed(2)}|${styles.join(',')}';
    return _cache.putIfAbsent(
      key,
      () => _resolver.resolve(
        document: _document,
        fontName: fontName,
        fontSize: fontSize,
        styles: styles,
      ),
    );
  }

  /// Pre-warms cache with unique font names from extracted text.
  void warmFromFontNames(
    Iterable<String> fontNames, {
    double sampleSize = 12,
  }) {
    for (final name in fontNames) {
      if (name.trim().isEmpty) continue;
      resolve(
        fontName: name,
        fontSize: sampleSize,
        styles: const [],
      );
    }
  }
}
