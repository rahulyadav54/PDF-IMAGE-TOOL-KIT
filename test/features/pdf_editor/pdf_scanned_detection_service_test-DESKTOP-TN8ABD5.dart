import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:pdf_image_toolbox/features/pdf_editor/models/editor_models.dart';
import 'package:pdf_image_toolbox/features/pdf_editor/services/pdf_scanned_detection_service.dart';

void main() {
  const service = PdfScannedDetectionService();

  test('detects text-based PDF', () {
    final document = PdfDocument();
    document.pages.add().graphics.drawString(
      'Hello world',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: const Rect.fromLTWH(50, 700, 200, 20),
    );

    expect(service.detect(document), PdfDocumentKind.textBased);
    document.dispose();
  });

  test('detects scanned PDF without text', () {
    final document = PdfDocument();
    document.pages.add();

    expect(service.detect(document), PdfDocumentKind.scanned);
    document.dispose();
  });
}
