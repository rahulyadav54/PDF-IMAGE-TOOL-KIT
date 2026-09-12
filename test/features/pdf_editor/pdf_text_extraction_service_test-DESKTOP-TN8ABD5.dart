import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:pdf_image_toolbox/features/pdf_editor/services/pdf_text_extraction_service.dart';

void main() {
  test('extracts text objects with font metadata from PDF', () {
    final document = PdfDocument();
    final page = document.pages.add();
    page.graphics.drawString(
      'Rahul Kumar',
      PdfStandardFont(PdfFontFamily.helvetica, 14),
      bounds: const Rect.fromLTWH(72, 700, 200, 20),
    );

    const service = PdfTextExtractionService();
    final objects = service.extractTextObjects(document);
    document.dispose();

    expect(objects, isNotEmpty);
    expect(
      objects.any((o) => o.originalText.contains('Rahul')),
      isTrue,
    );
    expect(objects.first.fontSize, greaterThan(0));
    expect(objects.first.fontName, isNotEmpty);
  });
}
