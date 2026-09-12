import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_image_toolbox/shared/models/recent_file.dart';

void main() {
  group('RecentFile', () {
    test('encodes and decodes list', () {
      final files = [
        RecentFile(
          id: '1',
          fileName: 'test.pdf',
          filePath: '/path/test.pdf',
          fileType: 'PDF',
          operation: 'Compress',
          processedAt: DateTime(2025, 1, 1, 12, 0),
          fileSizeBytes: 1024,
        ),
      ];

      final encoded = RecentFile.encodeList(files);
      final decoded = RecentFile.decodeList(encoded);

      expect(decoded.length, 1);
      expect(decoded.first.fileName, 'test.pdf');
      expect(decoded.first.fileSizeBytes, 1024);
    });
  });
}
