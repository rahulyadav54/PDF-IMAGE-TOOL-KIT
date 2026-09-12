import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_image_toolbox/shared/models/tool_catalog.dart';

void main() {
  test('search finds edit pdf tool', () {
    final results = ToolCatalog.search('edit');
    expect(results.any((e) => e.title == 'Edit PDF'), isTrue);
  });

  test('search supports multi-word queries', () {
    final results = ToolCatalog.search('compress pdf');
    expect(results.any((e) => e.title == 'Compress PDF'), isTrue);
  });

  test('search returns empty for unknown query', () {
    expect(ToolCatalog.search('zzzznotool'), isEmpty);
  });
}
