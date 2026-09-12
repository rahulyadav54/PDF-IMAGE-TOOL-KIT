import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_image_toolbox/features/batch_processor/engine/batch_operation.dart';
import 'package:pdf_image_toolbox/features/batch_processor/models/batch_operation_type.dart';
import 'package:pdf_image_toolbox/features/batch_processor/models/batch_result.dart';

void main() {
  group('BatchFileResult', () {
    test('tracks success and failure states', () {
      final success = BatchFileResult.successResult(
        inputPath: '/in/a.jpg',
        fileName: 'a.jpg',
        outputPath: '/out/a.jpg',
        outputSizeBytes: 50,
      );
      expect(success.success, isTrue);

      final failure = BatchFileResult.failure(
        inputPath: '/in/b.jpg',
        fileName: 'b.jpg',
        errorMessage: 'Failed',
      );
      expect(failure.success, isFalse);
      expect(failure.errorMessage, 'Failed');
    });
  });

  group('BatchOperation registry shape', () {
    test('operation type exposes picker extensions', () {
      expect(
        BatchOperationType.imageConvert.allowedExtensions,
        contains('jpg'),
      );
      expect(
        BatchOperationType.compressPdf.allowedExtensions,
        ['pdf'],
      );
    });

    test('batch operation wraps processor callback', () {
      final operation = BatchOperation(
        type: BatchOperationType.imageCompress,
        processor: ({
          required inputPath,
          required fileName,
          required config,
          pageCount,
        }) async {
          return BatchFileResult.successResult(
            inputPath: inputPath,
            fileName: fileName,
            outputPath: '/out/$fileName',
            outputSizeBytes: 10,
          );
        },
      );

      expect(operation.type, BatchOperationType.imageCompress);
    });
  });

  group('BatchRunResult', () {
    test('counts successes and failures', () {
      final result = BatchRunResult(
        operationLabel: 'Test',
        primaryOutputPath: '/out.zip',
        primaryFileName: 'out.zip',
        totalOutputBytes: 100,
        fileResults: [
          BatchFileResult.successResult(
            inputPath: '/a',
            fileName: 'a.jpg',
            outputPath: '/out/a.jpg',
            outputSizeBytes: 50,
          ),
          BatchFileResult.failure(
            inputPath: '/b',
            fileName: 'b.jpg',
            errorMessage: 'x',
          ),
        ],
      );

      expect(result.successCount, 1);
      expect(result.failureCount, 1);
      expect(result.failures.length, 1);
    });
  });
}
