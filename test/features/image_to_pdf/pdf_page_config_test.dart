import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf_image_toolbox/features/image_to_pdf/models/pdf_page_config.dart';

void main() {
  group('PdfPageConfig', () {
    test('resolves A4 portrait', () {
      const config = PdfPageConfig();
      final format = config.resolveFormat();
      expect(format.width, PdfPageFormat.a4.width);
      expect(format.height, PdfPageFormat.a4.height);
    });

    test('resolves A4 landscape', () {
      const config = PdfPageConfig(orientation: PdfPageOrientation.landscape);
      final format = config.resolveFormat();
      expect(format.width, PdfPageFormat.a4.landscape.width);
    });

    test('resolves fit to image dimensions', () {
      const config = PdfPageConfig(pageSize: PdfPageSizeOption.fitToImage);
      final format = config.resolveFormat(imageWidth: 720, imageHeight: 1280);
      expect(format.width, greaterThan(0));
      expect(format.height, greaterThan(0));
    });
  });
}
