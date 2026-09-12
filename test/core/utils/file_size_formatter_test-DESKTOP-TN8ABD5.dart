import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_image_toolbox/core/utils/file_size_formatter.dart';

void main() {
  group('FileSizeFormatter', () {
    test('formats bytes', () {
      expect(FileSizeFormatter.format(0), '0 B');
      expect(FileSizeFormatter.format(512), '512 B');
      expect(FileSizeFormatter.format(1024), '1.00 KB');
      expect(FileSizeFormatter.format(1536), '1.50 KB');
      expect(FileSizeFormatter.format(1048576), '1.00 MB');
      expect(FileSizeFormatter.format(1073741824), '1.00 GB');
    });

    test('calculates saved percent', () {
      expect(FileSizeFormatter.savedPercent(1000, 400), 60);
      expect(FileSizeFormatter.savedPercent(100, 100), isNull);
      expect(FileSizeFormatter.savedPercent(100, 150), isNull);
    });
  });
}
