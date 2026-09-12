import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_image_toolbox/shared/models/image_format.dart';

void main() {
  group('ImageFormat', () {
    test('detects extensions from path', () {
      expect(ImageFormat.fromPath('/photos/pic.JPG'), ImageFormat.jpg);
      expect(ImageFormat.fromPath('/photos/pic.jpeg'), ImageFormat.jpg);
      expect(ImageFormat.fromPath('/photos/pic.png'), ImageFormat.png);
      expect(ImageFormat.fromPath('/photos/pic.webp'), ImageFormat.webp);
    });

    test('identifies quality-capable formats', () {
      expect(ImageFormat.jpg.supportsQuality, isTrue);
      expect(ImageFormat.webp.supportsQuality, isTrue);
      expect(ImageFormat.png.supportsQuality, isFalse);
    });

    test('webp is input-only for encoding', () {
      expect(ImageFormat.webp.supportsEncoding, isFalse);
      expect(ImageFormat.png.supportsEncoding, isTrue);
    });
  });
}
