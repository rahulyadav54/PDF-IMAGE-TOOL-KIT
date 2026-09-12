import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_image_toolbox/features/batch_processor/models/batch_file_item.dart';
import 'package:pdf_image_toolbox/features/batch_processor/models/batch_operation_type.dart';
import 'package:pdf_image_toolbox/features/batch_processor/providers/batch_session_provider.dart';

void main() {
  group('BatchSessionNotifier', () {
    test('adds, removes, and resets files', () {
      final notifier = BatchSessionNotifier();
      const item = BatchFileItem(
        id: '1',
        filePath: '/tmp/a.jpg',
        fileName: 'a.jpg',
        fileSizeBytes: 100,
      );

      notifier.addFiles([item]);
      expect(notifier.state.files.length, 1);

      notifier.removeFile('1');
      expect(notifier.state.files, isEmpty);

      notifier.setOperation(BatchOperationType.compressPdf);
      expect(notifier.state.operationType, BatchOperationType.compressPdf);
      expect(notifier.state.files, isEmpty);

      notifier.clear();
      expect(notifier.state.operationType, BatchOperationType.imageConvert);
    });
  });
}
