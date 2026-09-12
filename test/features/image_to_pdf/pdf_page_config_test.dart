import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf_image_toolbox/features/image_to_pdf/models/pdf_page_config.dart';

void main() {
  group('PdfPageConfig', () {
    test('defaults to auto page size', () {
      const config = PdfPageConfig();
      expect(config.pageSize, PdfPageSizeOption.auto);
      expect(config.orientation, PdfPageOrientation.auto);
    });

    test('resolves A4 portrait', () {
      const config = PdfPageConfig(
        pageSize: PdfPageSizeOption.a4,
        orientation: PdfPageOrientation.portrait,
      );
      final format = config.resolveFormat(imageWidth: 800, imageHeight: 1200);
      expect(format.width, PdfPageFormat.a4.width);
      expect(format.height, PdfPageFormat.a4.height);
    });

    test('resolves A4 landscape for wide images in auto orientation', () {
      const config = PdfPageConfig(
        pageSize: PdfPageSizeOption.a4,
        orientation: PdfPageOrientation.auto,
      );
      final format = config.resolveFormat(imageWidth: 1600, imageHeight: 900);
      expect(format.width, PdfPageFormat.a4.landscape.width);
    });

    test('auto page size picks landscape for wide images', () {
      const config = PdfPageConfig();
      final format = config.resolveFormat(imageWidth: 1600, imageHeight: 900);
      expect(format.width, greaterThan(format.height));
    });

    test('auto page size picks portrait for tall images', () {
      const config = PdfPageConfig();
      final format = config.resolveFormat(imageWidth: 900, imageHeight: 1600);
      expect(format.height, greaterThan(format.width));
    });

    test('resolves fit to image dimensions', () {
      const config = PdfPageConfig(pageSize: PdfPageSizeOption.fitToImage);
      final format = config.resolveFormat(imageWidth: 720, imageHeight: 1280);
      expect(format.width, greaterThan(0));
      expect(format.height, greaterThan(0));
    });
  });
}
