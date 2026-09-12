import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Syncfusion only exposes drawn text to extractors after serializing the document.
Future<PdfDocument> materializePdf(PdfDocument document) async {
  final bytes = await document.save();
  document.dispose();
  return PdfDocument(inputBytes: bytes);
}
