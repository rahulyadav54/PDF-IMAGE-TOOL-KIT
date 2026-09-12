import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../compress_pdf/services/pdf_compression_service.dart';
import '../../image_compress/services/image_compress_service.dart';
import '../../image_convert/services/image_convert_service.dart';
import '../../image_resize/models/resize_mode.dart';
import '../../image_resize/services/image_resize_service.dart';
import '../models/batch_operation_type.dart';
import '../models/batch_result.dart';
import 'batch_operation.dart';

final batchOperationsRegistryProvider = Provider<List<BatchOperation>>((ref) {
  return [
    BatchOperation(
      type: BatchOperationType.imageConvert,
      processor: ({required inputPath, required fileName, required config, pageCount}) async {
        final result = await ref.read(imageConvertServiceProvider).convert(
          inputPath: inputPath,
          targetFormat: config.targetFormat,
        );
        return BatchFileResult.successResult(
          inputPath: inputPath,
          fileName: fileName,
          outputPath: result.outputPath,
          outputSizeBytes: result.outputSizeBytes,
        );
      },
    ),
    BatchOperation(
      type: BatchOperationType.imageCompress,
      processor: ({required inputPath, required fileName, required config, pageCount}) async {
        final result = await ref.read(imageCompressServiceProvider).compress(
          inputPath: inputPath,
          quality: config.quality,
        );
        return BatchFileResult.successResult(
          inputPath: inputPath,
          fileName: fileName,
          outputPath: result.outputPath,
          outputSizeBytes: result.compressedSizeBytes,
        );
      },
    ),
    BatchOperation(
      type: BatchOperationType.imageResize,
      processor: ({required inputPath, required fileName, required config, pageCount}) async {
        final result = await ref.read(imageResizeServiceProvider).resize(
          inputPath: inputPath,
          request: ImageResizeRequest(
            mode: ResizeMode.percentage,
            lockAspectRatio: true,
            percentage: config.resizePercentage,
          ),
        );
        return BatchFileResult.successResult(
          inputPath: inputPath,
          fileName: fileName,
          outputPath: result.outputPath,
          outputSizeBytes: result.outputSizeBytes,
        );
      },
    ),
    BatchOperation(
      type: BatchOperationType.compressPdf,
      processor: ({required inputPath, required fileName, required config, pageCount}) async {
        if (pageCount == null) {
          throw const InvalidFileException('PDF page count is unavailable.');
        }
        final result = await ref.read(pdfCompressionServiceProvider).compress(
          inputPath: inputPath,
          level: config.compressionLevel,
          pageCount: pageCount,
        );
        return BatchFileResult.successResult(
          inputPath: inputPath,
          fileName: fileName,
          outputPath: result.outputPath,
          outputSizeBytes: result.compressedSizeBytes,
        );
      },
    ),
  ];
});
