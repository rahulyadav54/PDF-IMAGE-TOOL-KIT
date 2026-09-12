import '../models/batch_operation_type.dart';
import '../models/batch_result.dart';

typedef BatchFileProcessor = Future<BatchFileResult> Function({
  required String inputPath,
  required String fileName,
  required BatchConfig config,
  int? pageCount,
});

/// Definition for a registerable batch operation.
class BatchOperation {
  const BatchOperation({
    required this.type,
    required this.processor,
  });

  final BatchOperationType type;
  final BatchFileProcessor processor;
}
