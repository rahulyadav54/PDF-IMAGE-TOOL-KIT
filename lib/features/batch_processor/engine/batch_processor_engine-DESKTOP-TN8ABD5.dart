import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/services/file_service.dart';
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
  }) async {
    if (items.isEmpty) {
      throw const ProcessingException('Add at least one file to process.');
    }

    final results = <BatchFileResult>[];
    var totalBytes = 0;

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      onProgress?.call(
        BatchProgress(
          current: i + 1,
          total: items.length,
          currentFileName: item.fileName,
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
        results.add(
          BatchFileResult.failure(
            inputPath: item.filePath,
            fileName: item.fileName,
            errorMessage: e.message,
          ),
        );
      } catch (_) {
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
    final archive = Archive();

    for (final result in successes) {
      final file = File(result.outputPath!);
      final bytes = await file.readAsBytes();
      archive.addFile(
        ArchiveFile(file.uri.pathSegments.last, bytes.length, bytes),
      );
    }

    final zipBytes = ZipEncoder().encode(archive);
    final zipFileName = FilenameGenerator.batchZip(operationId);
    final zipPath = await _ref.read(fileServiceProvider).saveToOutput(
      zipFileName,
      zipBytes,
    );

    return _ZipOutput(path: zipPath, fileName: zipFileName);
  }
}

class _ZipOutput {
  const _ZipOutput({required this.path, required this.fileName});

  final String path;
  final String fileName;
}
