import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_image_toolbox/features/merge_pdf/models/merge_pdf_item.dart';
import 'package:pdf_image_toolbox/features/merge_pdf/providers/merge_session_provider.dart';

MergePdfItem _item(String id, String path, {int pages = 1, int bytes = 100}) {
  return MergePdfItem(
    id: id,
    filePath: path,
    fileName: '$id.pdf',
    pageCount: pages,
    fileSizeBytes: bytes,
  );
}

void main() {
  test('merge session add, reorder, remove, and totals', () {
    final container = ProviderContainer();
    final notifier = container.read(mergeSessionProvider.notifier);

    notifier.addItems([
      _item('1', '/a.pdf', pages: 2, bytes: 100),
      _item('2', '/b.pdf', pages: 3, bytes: 200),
    ]);
    expect(container.read(mergeSessionProvider).length, 2);
    expect(notifier.totalPages, 5);
    expect(notifier.totalBytes, 300);

    notifier.reorder(0, 2);
    expect(container.read(mergeSessionProvider).first.id, '2');

    notifier.remove('2');
    expect(container.read(mergeSessionProvider).length, 1);

    notifier.addItems([_item('1', '/a.pdf')]);
    expect(container.read(mergeSessionProvider).length, 1);

    container.dispose();
  });
}
