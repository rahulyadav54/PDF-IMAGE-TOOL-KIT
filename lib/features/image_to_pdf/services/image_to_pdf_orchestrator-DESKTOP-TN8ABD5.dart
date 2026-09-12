import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../shared/services/bulk_processing/cancel_token.dart';
import '../../scan_to_pdf/services/image_enhancement_service.dart';
import '../models/image_pdf_item.dart';
import '../models/image_pdf_processing_options.dart';
import '../models/pdf_page_config.dart';
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
    final paths = <String>[];
    final failedItems = <ImagePdfItem>[];
    var enhancedCount = 0;

    if (options.processingMode == ImagePdfProcessingMode.original) {
      paths.addAll(validImages.map((e) => e.filePath));
    } else {
      final toEnhance = validImages.where((item) {
        if (options.processingMode == ImagePdfProcessingMode.enhanceAll) {
          return true;
        }
        return item.selectedForEnhancement;
      }).toList();

      onStage?.call(
        stage: 'enhance',
        current: 0,
        total: toEnhance.length,
        detail: 'Improving text clarity...',
      );

      final enhanceService = _ref.read(imageEnhancementServiceProvider);
      final enhanceResult = await enhanceService.enhanceMany(
        sourcePaths: toEnhance.map((e) => e.filePath).toList(),
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

        final shouldEnhance = options.processingMode ==
                ImagePdfProcessingMode.enhanceAll ||
            item.selectedForEnhancement;

        if (!shouldEnhance) {
          paths.add(item.filePath);
          continue;
        }

        final enhanced = enhanceResult.outputPaths[item.filePath];
        if (enhanced != null) {
          paths.add(enhanced);
          enhancedCount++;
        } else {
          final message = enhanceResult.failedPaths[item.filePath];
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
    final pdfResult = await pdfService.generate(
      imagePaths: paths,
      config: config,
      maxWidth: options.effectiveMaxDimension,
      jpegQuality: options.effectiveJpegQuality,
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

    return ImageToPdfJobResult(
      pdfResult: pdfResult,
      enhancedCount: enhancedCount,
      failedItems: failedItems,
      skippedCount: failedItems.length,
    );
  }
}
