import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_image_toolbox/features/compress_pdf/models/compression_level.dart';

void main() {
  group('CompressionLevel', () {
    test('estimates compressed size with ratio', () {
      const original = 10 * 1024 * 1024;
      final estimated = CompressionLevel.estimateCompressedSize(
        original,
        CompressionLevel.medium,
      );
      expect(estimated, (original * CompressionLevel.medium.estimatedRatio).round());
    });

    test('high quality does not rasterize', () {
      expect(CompressionLevel.high.useRasterize, isFalse);
      expect(CompressionLevel.low.useRasterize, isTrue);
    });
  });
}
