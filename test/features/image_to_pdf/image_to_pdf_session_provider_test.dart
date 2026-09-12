import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_image_toolbox/features/image_to_pdf/models/image_pdf_item.dart';
import 'package:pdf_image_toolbox/features/image_to_pdf/models/pdf_page_config.dart';
import 'package:pdf_image_toolbox/features/image_to_pdf/providers/image_to_pdf_session_provider.dart';

ImagePdfItem _item(String id, String path) => ImagePdfItem(
      id: id,
      filePath: path,
      fileName: '$id.jpg',
      fileSizeBytes: 100,
    );

void main() {
  test('image session add, reorder, remove, and config', () {
    final container = ProviderContainer();
    final notifier = container.read(imageToPdfSessionProvider.notifier);

    notifier.addImages([_item('1', '/a.jpg'), _item('2', '/b.jpg')]);
    expect(container.read(imageToPdfSessionProvider).images.length, 2);

    notifier.reorder(0, 2);
    expect(container.read(imageToPdfSessionProvider).images.first.id, '2');

    notifier.updateConfig(
      const PdfPageConfig(orientation: PdfPageOrientation.landscape),
    );
    expect(
      container.read(imageToPdfSessionProvider).config.orientation,
      PdfPageOrientation.landscape,
    );

    notifier.remove('2');
    expect(container.read(imageToPdfSessionProvider).images.length, 1);

    container.dispose();
  });
}
