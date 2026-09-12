import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/editor_models.dart';

final pdfScannedDetectionServiceProvider =
    Provider<PdfScannedDetectionService>((ref) => const PdfScannedDetectionService());

class PdfScannedDetectionService {
  const PdfScannedDetectionService();

  PdfDocumentKind detect(PdfDocument document) {
    final pageCount = document.pages.count;
    if (pageCount == 0) return PdfDocumentKind.scanned;

    final extractor = PdfTextExtractor(document);
    final lines = extractor.extractTextLines();
    final meaningful = lines.where((l) => l.text.trim().length > 2).length;

    if (meaningful == 0) return PdfDocumentKind.scanned;
    if (meaningful < pageCount) return PdfDocumentKind.mixed;
    return PdfDocumentKind.textBased;
  }

  bool isLikelyScanned(PdfDocument document) {
    final kind = detect(document);
    return kind == PdfDocumentKind.scanned || kind == PdfDocumentKind.mixed;
  }
}
