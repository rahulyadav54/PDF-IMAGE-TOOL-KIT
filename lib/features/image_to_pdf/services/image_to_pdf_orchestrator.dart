import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../shared/services/bulk_processing/cancel_token.dart';
import '../../../shared/services/bulk_processing/worker_pool.dart';
import '../../../shared/services/cache_maintenance_service.dart';
import '../../../shared/services/storage_guard_service.dart';
import '../../../shared/services/temp_file_service.dart';
import '../../scan_to_pdf/services/image_enhancement_service.dart';
import '../models/image_pdf_item.dart';
import '../models/image_pdf_processing_options.dart';
import '../models/pdf_page_config.dart';
import 'image_to_pdf_isolate.dart';
import 'image_to_pdf_service.dart';

final imageToPdfOrchestratorProvider =
    Provider<ImageToPdfOrchestrator>((ref) => ImageToPdfOrchestrator(ref));

class ImageToPdfJobResult {
  const ImageToPdfJobResult({
    required this.pdfResult,
    required this.enhancedCount,
    required this.failedItems,
    required this.skippedCount,
  });

  final ImageToPdfResult pdfResult;
  final int enhancedCount;
  final List<ImagePdfItem> failedItems;
  final int skippedCount;
}

typedef ImageToPdfStageCallback = void Function({
  required String stage,
  required int current,
  required int total,
  String? detail,
});

class ImageToPdfOrchestrator {
  ImageToPdfOrchestrator(this._ref);

  final Ref _ref;

  Future<ImageToPdfJobResult> run({
    required List<ImagePdfItem> images,
    required PdfPageConfig config,
    required ImagePdfProcessingOptions options,
    CancelToken? cancelToken,
    ImageToPdfStageCallback? onStage,
  }) async {
    final validImages = images.where((item) => !item.failed).toList();
    final failedItems = <ImagePdfItem>[];
    var enhancedCount = 0;

    await _ref.read(storageGuardServiceProvider).ensureSpaceForPaths(
          validImages.map((e) => e.filePath).toList(),
        );

    onStage?.call(
      stage: 'prepare',
      current: 0,
      total: validImages.length,
      detail: 'Analyzing orientation and document bounds...',
    );

    final preparedSources = await _prepareSources(
      validImages,
      options: options,
      cancelToken: cancelToken,
      onProgress: (current, total) {
        onStage?.call(
          stage: 'prepare',
          current: current,
          total: total,
          detail: 'Preparing $current of $total images',
        );
      },
      failedItems: failedItems,
    );

    if (preparedSources.isEmpty) {
      throw const ProcessingException(
        'No valid images available to create a PDF.',
      );
    }

    final paths = <String>[];
    final preprocessedPaths = <String>{};

    if (options.processingMode == ImagePdfProcessingMode.original) {
      for (final entry in preparedSources.entries) {
        paths.add(entry.value);
        preprocessedPaths.add(entry.value);
      }
    } else {
      final toEnhance = <ImagePdfItem>[];
      for (final item in validImages) {
        final shouldEnhance = options.processingMode ==
                ImagePdfProcessingMode.enhanceAll ||
            item.selectedForEnhancement;
        if (shouldEnhance && preparedSources.containsKey(item.filePath)) {
          toEnhance.add(item);
        }
      }

      onStage?.call(
        stage: 'enhance',
        current: 0,
        total: toEnhance.length,
        detail: 'Improving text clarity...',
      );

      final enhanceService = _ref.read(imageEnhancementServiceProvider);
      final enhanceInputs = toEnhance
          .map((item) => preparedSources[item.filePath]!)
          .toList();
      final enhanceResult = await enhanceService.enhanceMany(
        sourcePaths: enhanceInputs,
        kind: options.enhancementKind,
        maxDimension: options.effectiveMaxDimension,
        jpegQuality: options.effectiveJpegQuality,
        cancelToken: cancelToken,
        onProgress: (current, total) {
          onStage?.call(
            stage: 'enhance',
            current: current,
            total: total,
            detail: 'Improving $current of $total images',
          );
        },
      );

      for (final item in validImages) {
        cancelToken?.throwIfCancelled();
        final preparedPath = preparedSources[item.filePath];
        if (preparedPath == null) continue;

        final shouldEnhance = options.processingMode ==
                ImagePdfProcessingMode.enhanceAll ||
            item.selectedForEnhancement;

        if (!shouldEnhance) {
          paths.add(preparedPath);
          preprocessedPaths.add(preparedPath);
          continue;
        }

        final enhanced = enhanceResult.outputPaths[preparedPath];
        if (enhanced != null) {
          paths.add(enhanced);
          preprocessedPaths.add(enhanced);
          enhancedCount++;
        } else {
          final message = enhanceResult.failedPaths[preparedPath];
          failedItems.add(
            item.copyWith(
              failed: true,
              failureMessage: message ?? 'Could not enhance image.',
            ),
          );
        }
      }
    }

    if (paths.isEmpty) {
      throw const ProcessingException(
        'No valid images available to create a PDF.',
      );
    }

    onStage?.call(
      stage: 'pdf',
      current: 0,
      total: paths.length,
      detail: 'Creating PDF...',
    );

    final pdfService = _ref.read(imageToPdfServiceProvider);
    final batchSize = paths.length;
    final adaptiveMaxWidth = batchSize > 100
        ? options.effectiveMaxDimension.clamp(1200, 1800)
        : options.effectiveMaxDimension;
    final adaptiveQuality = batchSize > 100
        ? options.effectiveJpegQuality.clamp(72, 82)
        : options.effectiveJpegQuality;

    final pdfResult = await pdfService.generate(
      imagePaths: paths,
      config: config,
      maxWidth: adaptiveMaxWidth,
      jpegQuality: adaptiveQuality,
      preprocessedPaths: preprocessedPaths,
      cancelToken: cancelToken,
      onProgress: (current, total) {
        onStage?.call(
          stage: 'pdf',
          current: current,
          total: total,
          detail: 'Page $current of $total',
        );
      },
    );

    await _ref.read(cacheMaintenanceServiceProvider).runAfterHeavyJob();

    return ImageToPdfJobResult(
      pdfResult: pdfResult,
      enhancedCount: enhancedCount,
      failedItems: failedItems,
      skippedCount: failedItems.length,
    );
  }

  Future<Map<String, String>> _prepareSources(
    List<ImagePdfItem> images, {
    required ImagePdfProcessingOptions options,
    CancelToken? cancelToken,
    void Function(int current, int total)? onProgress,
    required List<ImagePdfItem> failedItems,
  }) async {
    final tempService = _ref.read(tempFileServiceProvider);

    final pairs = await WorkerPool.mapConcurrent<ImagePdfItem, (String, String)?>(
      items: images,
      concurrency: WorkerPool.recommendedImageConcurrency(itemCount: images.length),
      cancelToken: cancelToken,
      onProgress: onProgress,
      worker: (item, index) async {
        try {
          final rawBytes = await File(item.filePath).readAsBytes();
          final prepared = await compute(
            preparePdfPageInIsolate,
            PreparePdfPageParams(
              bytes: rawBytes,
              maxWidth: options.effectiveMaxDimension,
              jpegQuality: options.effectiveJpegQuality,
            ),
          );
          final tempPath = await tempService.createTempFile(extension: '.jpg');
          await File(tempPath).writeAsBytes(prepared.bytes, flush: true);
          return (item.filePath, tempPath);
        } catch (_) {
          return null;
        }
      },
    );

    final results = <String, String>{};
    for (var i = 0; i < pairs.length; i++) {
      final pair = pairs[i];
      if (pair != null) {
        results[pair.$1] = pair.$2;
      } else {
        failedItems.add(
          images[i].copyWith(
            failed: true,
            failureMessage: 'Could not prepare image.',
          ),
        );
      }
    }

    return results;
  }
}
