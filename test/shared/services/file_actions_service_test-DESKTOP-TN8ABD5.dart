import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_image_toolbox/shared/services/file_actions_service.dart';

void main() {
  final service = FileActionsService();

  group('FileActionsService file type detection', () {
    test('detects images', () {
      expect(service.isImage('/tmp/photo.jpg'), isTrue);
      expect(service.isImage('/tmp/photo.PNG'), isTrue);
      expect(service.isPdf('/tmp/photo.jpg'), isFalse);
    });

    test('detects pdfs', () {
      expect(service.isPdf('/tmp/doc.pdf'), isTrue);
      expect(service.isImage('/tmp/doc.pdf'), isFalse);
    });

    test('detects zip archives', () {
      expect(service.isZip('/tmp/files.zip'), isTrue);
    });
  });
}
