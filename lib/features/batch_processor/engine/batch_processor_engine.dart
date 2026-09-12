import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../core/utils/path_security.dart';
import '../../../shared/services/bulk_processing/cancel_token.dart';
import '../../../shared/services/file_service.dart';
import '../../../shared/services/temp_file_service.dart';
import '../models/batch_file_item.dart';
import '../models/batch_operation_type.dart';
import '../models/batch_result.dart';
import 'batch_operation.dart';

final batchProcessorEngineProvider =
    Provider<BatchProcessorEngine>((ref) => BatchProcessorEngine(ref));

typedef BatchProgressCallback = void Function(BatchProgress progress);

/// Runs batch operations sequentially with per-file error handling.
class BatchProcessorEngine {
  BatchProcessorEngine(this._ref);

  final Ref _ref;

  Future<BatchRunResult> run({
    required BatchOperation operation,
    required List<BatchFileItem> items,
    required BatchConfig config,
    BatchProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (items.isEmpty) {
      throw const ProcessingException('Add at least one file to process.');
    }

    final results = <BatchFileResult>[];
    var totalBytes = 0;
    var failedCount = 0;

    for (var i = 0; i < items.length; i++) {
      cancelToken?.throwIfCancelled();
      final item = items[i];
      onProgress?.call(
        BatchProgress(
          current: i + 1,
          total: items.length,
          currentFileName: item.fileName,
          failedCount: failedCount,
        ),
      );

      try {
        final result = await operation.processor(
          inputPath: item.filePath,
          fileName: item.fileName,
          config: config,
          pageCount: item.pageCount,
        );
        results.add(result);
        if (result.success && result.outputSizeBytes != null) {
          totalBytes += result.outputSizeBytes!;
        }
      } on AppException catch (e) {
        failedCount++;
        results.add(
          BatchFileResult.failure(
            inputPath: item.filePath,
            fileName: item.fileName,
            errorMessage: e.message,
          ),
        );
      } catch (_) {
        failedCount++;
        results.add(
          BatchFileResult.failure(
            inputPath: item.filePath,
            fileName: item.fileName,
            errorMessage: 'Unable to process this file.',
          ),
        );
      }
    }

    final successes = results.where((r) => r.success && r.outputPath != null).toList();
    if (successes.isEmpty) {
      throw const ProcessingException(
        'No files were processed successfully. Check the failed items and try again.',
      );
    }

    if (successes.length == 1) {
      final only = successes.first;
      return BatchRunResult(
        operationLabel: operation.type.label,
        fileResults: results,
        primaryOutputPath: only.outputPath!,
        primaryFileName: File(only.outputPath!).uri.pathSegments.last,
        totalOutputBytes: totalBytes,
      );
    }

    final zip = await _createZip(operation.type.id, successes);
    return BatchRunResult(
      operationLabel: operation.type.label,
      fileResults: results,
      primaryOutputPath: zip.path,
      primaryFileName: zip.fileName,
      totalOutputBytes: totalBytes,
      zipPath: zip.path,
    );
  }

  Future<_ZipOutput> _createZip(
    String operationId,
    List<BatchFileResult> successes,
  ) async {
    final fileService = _ref.read(fileServiceProvider);
    final tempService = _ref.read(tempFileServiceProvider);
    final zipFileName = FilenameGenerator.batchZip(operationId);
    final tempZipPath = await tempService.createTempFile(extension: '.zip');

    final encoder = ZipFileEncoder();
    encoder.create(tempZipPath);
    for (final result in successes) {
      encoder.addFile(File(result.outputPath!));
    }
    encoder.close();

    final outputDir = await fileService.getOutputDirectory();
    final outputPath = PathSecurity.outputPath(outputDir, zipFileName);
    await File(tempZipPath).copy(outputPath);
    await tempService.delete(tempZipPath);

    return _ZipOutput(path: outputPath, fileName: zipFileName);
  }
}

class _ZipOutput {
  const _ZipOutput({required this.path, required this.fileName});

  final String path;
  final String fileName;
}
