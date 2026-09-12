import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_image_toolbox/core/utils/filename_generator.dart';

void main() {
  group('FilenameGenerator', () {
    test('generates merged filename', () {
      final name = FilenameGenerator.merged('document.pdf');
      expect(name, startsWith('document_merged_'));
      expect(name, endsWith('.pdf'));
    });

    test('generates split page filename', () {
      final name = FilenameGenerator.splitPage('/path/report.pdf', 2);
      expect(name, contains('report_split_002.pdf'));
    });

    test('generates converted filename', () {
      final name = FilenameGenerator.converted('/path/photo.jpg', 'png');
      expect(name, 'photo_converted.png');
    });

    test('generates scanned filename', () {
      final name = FilenameGenerator.scanned();
      expect(name, startsWith('scanned_document_'));
      expect(name, endsWith('.pdf'));
    });

    test('generates extracted range filename', () {
      final name = FilenameGenerator.extractedRange('/path/report.pdf', 2, 4);
      expect(name, startsWith('report_pages_2-4_'));
      expect(name, endsWith('.pdf'));
    });

    test('generates split zip filename', () {
      final name = FilenameGenerator.splitZip('/path/report.pdf');
      expect(name, startsWith('report_split_pages_'));
      expect(name, endsWith('.zip'));
    });

    test('generates image compressed filename', () {
      final name = FilenameGenerator.imageCompressed('/path/photo.jpg');
      expect(name, startsWith('photo_compressed'));
      expect(name, endsWith('.jpg'));
    });

    test('generates image resized filename', () {
      final name = FilenameGenerator.imageResized('/path/photo.png');
      expect(name, startsWith('photo_resized'));
      expect(name, endsWith('.png'));
    });

    test('generates batch zip filename', () {
      final name = FilenameGenerator.batchZip('image_convert');
      expect(name, startsWith('batch_image_convert_'));
      expect(name, endsWith('.zip'));
    });
  });
}
