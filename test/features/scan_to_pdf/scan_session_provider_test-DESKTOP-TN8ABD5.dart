import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_image_toolbox/features/scan_to_pdf/providers/scan_session_provider.dart';

void main() {
  test('scan session add, reorder, and remove pages', () async {
    final container = ProviderContainer();
    final notifier = container.read(scanSessionProvider.notifier);

    notifier.addPages(['/tmp/page1.jpg', '/tmp/page2.jpg', '/tmp/page3.jpg']);
    expect(container.read(scanSessionProvider).length, 3);

    notifier.addPage('/tmp/page4.jpg');
    expect(container.read(scanSessionProvider).length, 4);

    notifier.reorder(0, 2);
    expect(container.read(scanSessionProvider).first.displayImagePath, '/tmp/page2.jpg');

    final id = container.read(scanSessionProvider).first.id;
    await notifier.removePage(id);
    expect(container.read(scanSessionProvider).length, 3);

    container.dispose();
  });
}
