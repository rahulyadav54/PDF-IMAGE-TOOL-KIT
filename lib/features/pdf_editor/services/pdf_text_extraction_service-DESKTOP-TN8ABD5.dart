import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';

import '../models/editor_models.dart';

final pdfTextExtractionServiceProvider =
    Provider<PdfTextExtractionService>((ref) => const PdfTextExtractionService());

class PdfTextExtractionService {
  const PdfTextExtractionService();

  static const _uuid = Uuid();

  /// Extracts line-level text only (no duplicate word objects).
  List<PdfTextObjectMetadata> extractTextObjects(PdfDocument document) {
    final extractor = PdfTextExtractor(document);
    final lines = extractor.extractTextLines();
    final objects = <PdfTextObjectMetadata>[];

    for (final line in lines) {
      final text = line.text.trim();
      if (text.isEmpty) continue;

      final styles = line.fontStyle;
      objects.add(
        PdfTextObjectMetadata(
          id: _uuid.v4(),
          pageIndex: line.pageIndex,
          originalText: line.text,
          fontName: line.fontName,
          fontFamily: _resolveFamily(line.fontName),
          fontSize: line.fontSize,
          fontWeight: styles.contains(PdfFontStyle.bold) ? 'bold' : 'normal',
          fontStyle: styles,
          color: const Color(0xFF000000),
          characterSpacing: 0,
          lineSpacing: line.fontSize * 0.2,
          alignment: TextAlign.left,
          bounds: line.bounds,
          rotation: _rotationFromLine(line),
          fontPreserved: true,
        ),
      );
    }

    return _mergeAdjacentLines(objects);
  }

  List<PdfTextObjectMetadata> extractForPage(
    PdfDocument document,
    int pageIndex,
  ) {
    final extractor = PdfTextExtractor(document);
    final lines = extractor.extractTextLines(
      startPageIndex: pageIndex,
      endPageIndex: pageIndex,
    );
    final objects = <PdfTextObjectMetadata>[];

    for (final line in lines) {
      if (line.text.trim().isEmpty) continue;
      final styles = line.fontStyle;
      objects.add(
        PdfTextObjectMetadata(
          id: _uuid.v4(),
          pageIndex: line.pageIndex,
          originalText: line.text,
          fontName: line.fontName,
          fontFamily: _resolveFamily(line.fontName),
          fontSize: line.fontSize,
          fontWeight: styles.contains(PdfFontStyle.bold) ? 'bold' : 'normal',
          fontStyle: styles,
          color: const Color(0xFF000000),
          characterSpacing: 0,
          lineSpacing: line.fontSize * 0.2,
          alignment: TextAlign.left,
          bounds: line.bounds,
          rotation: _rotationFromLine(line),
          fontPreserved: true,
        ),
      );
    }
    return objects;
  }

  List<PdfTextObjectMetadata> _mergeAdjacentLines(
    List<PdfTextObjectMetadata> input,
  ) {
    if (input.length <= 1) return input;

    final sorted = List<PdfTextObjectMetadata>.of(input)
      ..sort((a, b) {
        if (a.pageIndex != b.pageIndex) return a.pageIndex.compareTo(b.pageIndex);
        final top = a.bounds.top.compareTo(b.bounds.top);
        if (top != 0) return top;
        return a.bounds.left.compareTo(b.bounds.left);
      });

    final merged = <PdfTextObjectMetadata>[sorted.first];
    for (var i = 1; i < sorted.length; i++) {
      final prev = merged.last;
      final current = sorted[i];
      final overlaps = prev.pageIndex == current.pageIndex &&
          prev.bounds.overlaps(current.bounds.inflate(1));
      if (overlaps && prev.originalText.trim() == current.originalText.trim()) {
        continue;
      }
      merged.add(current);
    }
    return merged;
  }

  String _resolveFamily(String fontName) {
    final normalized = fontName.toLowerCase();
    if (normalized.contains('times')) return 'Times';
    if (normalized.contains('courier')) return 'Courier';
    if (normalized.contains('symbol')) return 'Symbol';
    if (normalized.contains('zapf')) return 'ZapfDingbats';
    if (normalized.contains('arial') || normalized.contains('helvetica')) {
      return 'Helvetica';
    }
    if (normalized.contains('+')) {
      return fontName.split('+').last.split('-').first;
    }
    return fontName.split('-').first;
  }

  double _rotationFromLine(TextLine line) {
    if (line.wordCollection.any((w) => w.glyphs.any((g) => g.isRotated))) {
      return 90;
    }
    return 0;
  }
}
