import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_image_toolbox/core/utils/filename_generator.dart';

void main() {
  group('PDF to image filenames', () {
    test('generates page image filename', () {
      final name = FilenameGenerator.pdfPageImage('/path/report.pdf', 2, 'jpg');
      expect(name, 'report_page_002.jpg');
    });

    test('generates zip filename', () {
      final name = FilenameGenerator.pdfToImageZip('/path/report.pdf');
      expect(name, startsWith('report_pages_'));
      expect(name, endsWith('.zip'));
    });
  });
}
