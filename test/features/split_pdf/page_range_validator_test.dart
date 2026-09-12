import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_image_toolbox/features/split_pdf/utils/page_range_validator.dart';

void main() {
  group('PageRangeValidator', () {
    test('validates page ranges', () {
      expect(PageRangeValidator.validate(1, 3, 5), isNull);
      expect(PageRangeValidator.validate(3, 2, 5), isNotNull);
      expect(PageRangeValidator.validate(0, 2, 5), isNotNull);
      expect(PageRangeValidator.validate(1, 6, 5), isNotNull);
    });

    test('converts to zero-based indices', () {
      expect(PageRangeValidator.toPageIndices(2, 4), [1, 2, 3]);
      expect(PageRangeValidator.toPageIndices(3, 3), [2]);
    });
  });
}
