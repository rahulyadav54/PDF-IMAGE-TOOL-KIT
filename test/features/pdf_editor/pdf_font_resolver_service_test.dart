import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:pdf_image_toolbox/features/pdf_editor/services/pdf_font_resolver_service.dart';

void main() {
  const resolver = PdfFontResolverService();

  test('preserves Times font for Times-Roman PDF names', () {
    final document = PdfDocument();
    final result = resolver.resolve(
      document: document,
      fontName: 'Times-Roman',
      fontSize: 12,
      styles: const [],
    );
    document.dispose();

    expect(result.preserved, isTrue);
    expect(result.font, isA<PdfStandardFont>());
    expect((result.font as PdfStandardFont).fontFamily, PdfFontFamily.timesRoman);
  });

  test('warns when substituting unknown embedded font', () {
    final document = PdfDocument();
    final result = resolver.resolve(
      document: document,
      fontName: 'ABCDEF+CustomFontXYZ',
      fontSize: 11,
      styles: const [PdfFontStyle.bold],
    );
    document.dispose();

    expect(result.preserved, isFalse);
    expect(result.notice, isNotNull);
  });
}
