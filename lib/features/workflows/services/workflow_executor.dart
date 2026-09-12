import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../features/compress_pdf/models/compression_level.dart';
import '../../../features/compress_pdf/services/pdf_compression_service.dart';
import '../../../features/image_to_pdf/models/pdf_page_config.dart';
import '../../../features/image_to_pdf/services/image_to_pdf_service.dart';
import '../../../shared/services/bulk_processing/cancel_token.dart';
import '../../../features/protect_pdf/services/pdf_protect_service.dart';
import '../../../features/scan_to_pdf/models/scan_enhance_kind.dart';
import '../../../features/scan_to_pdf/services/image_enhancement_service.dart';
import '../../../features/searchable_pdf/services/searchable_pdf_service.dart';
import '../models/workflow_definition.dart';
import '../models/workflow_operation.dart';

final workflowExecutorProvider =
    Provider<WorkflowExecutor>((ref) => WorkflowExecutor(ref));

class WorkflowStepFailure {
  const WorkflowStepFailure({
    required this.stepIndex,
    required this.stepLabel,
    required this.message,
  });

  final int stepIndex;
  final String stepLabel;
  final String message;
}

class WorkflowRunResult {
  const WorkflowRunResult({
    required this.outputPath,
    required this.completedSteps,
    this.failure,
  });

  final String outputPath;
  final int completedSteps;
  final WorkflowStepFailure? failure;

  bool get succeeded => failure == null;
}

typedef WorkflowProgress = void Function(
  int stepIndex,
  int totalSteps,
  String stepLabel,
  int itemCurrent,
  int itemTotal,
);

class WorkflowExecutor {
  WorkflowExecutor(this._ref);

  final Ref _ref;

  Future<WorkflowRunResult> execute({
    required ExecutableWorkflow workflow,
    required List<String> inputPaths,
    WorkflowProgress? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (inputPaths.isEmpty) {
      throw const ProcessingException('Add files to start this workflow.');
    }

    var currentPaths = List<String>.from(inputPaths);
    var currentPdfPath = workflow.inputType == WorkflowInputType.pdf
        ? inputPaths.first
        : null;
    var stepIndex = 0;

    for (final step in workflow.operations.where((s) => s.enabled)) {
      cancelToken?.throwIfCancelled();
      onProgress?.call(stepIndex, workflow.operations.length, step.label, 0, 1);

      try {
        switch (step.operation) {
          case WorkflowOperationType.enhance:
            currentPaths = await _enhanceImages(
              currentPaths,
              step.config['mode'] as String? ?? 'document',
              onProgress: (c, t) => onProgress?.call(
                stepIndex,
                workflow.operations.length,
                step.label,
                c,
                t,
              ),
              cancelToken: cancelToken,
            );
          case WorkflowOperationType.createPdf:
            final result = await _ref.read(imageToPdfServiceProvider).generate(
                  imagePaths: currentPaths,
                  config: const PdfPageConfig(),
                );
            currentPdfPath = result.outputPath;
          case WorkflowOperationType.compress:
            if (currentPdfPath == null) {
              throw const ProcessingException('No PDF available to compress.');
            }
            final compressed = await _ref.read(pdfCompressionServiceProvider).compress(
                  inputPath: currentPdfPath!,
                  level: CompressionLevel.medium,
                  pageCount: 1,
                );
            currentPdfPath = compressed.outputPath;
          case WorkflowOperationType.searchablePdf:
            if (currentPdfPath == null) {
              throw const ProcessingException('No PDF available for OCR.');
            }
            final searchable = await _ref
                .read(searchablePdfServiceProvider)
                .makeSearchable(inputPath: currentPdfPath!);
            currentPdfPath = searchable.outputPath;
          case WorkflowOperationType.protect:
            if (currentPdfPath == null) {
              throw const ProcessingException('No PDF available to protect.');
            }
            final password = step.config['password'] as String? ?? '1234';
            final protected = await _ref.read(pdfProtectServiceProvider).protect(
                  inputPath: currentPdfPath!,
                  password: password,
                  pageCount: 1,
                );
            currentPdfPath = protected.outputPath;
          case WorkflowOperationType.ocr:
            break;
        }
      } on AppException catch (e) {
        return WorkflowRunResult(
          outputPath: currentPdfPath ?? currentPaths.first,
          completedSteps: stepIndex,
          failure: WorkflowStepFailure(
            stepIndex: stepIndex,
            stepLabel: step.label,
            message: e.message,
          ),
        );
      } catch (_) {
        return WorkflowRunResult(
          outputPath: currentPdfPath ?? currentPaths.first,
          completedSteps: stepIndex,
          failure: WorkflowStepFailure(
            stepIndex: stepIndex,
            stepLabel: step.label,
            message: 'Unable to complete this step.',
          ),
        );
      }

      stepIndex++;
    }

    final output = currentPdfPath ?? currentPaths.first;
    if (!await File(output).exists()) {
      throw const ProcessingException('Workflow did not produce an output file.');
    }

    return WorkflowRunResult(
      outputPath: output,
      completedSteps: stepIndex,
    );
  }

  Future<List<String>> _enhanceImages(
    List<String> paths,
    String modeName, {
    void Function(int current, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final kind = _enhanceKindFromName(modeName);
    final service = _ref.read(imageEnhancementServiceProvider);
    final result = await service.enhanceMany(
      sourcePaths: paths,
      kind: kind,
      cancelToken: cancelToken,
      onProgress: onProgress,
    );
    return paths
        .map((p) => result.outputPaths[p] ?? p)
        .where((p) => File(p).existsSync())
        .toList();
  }

  ScanEnhanceKind _enhanceKindFromName(String name) {
    switch (name) {
      case 'blackAndWhite':
        return ScanEnhanceKind.blackWhite;
      case 'magicColor':
        return ScanEnhanceKind.magicColor;
      case 'grayscale':
        return ScanEnhanceKind.grayscale;
      case 'auto':
        return ScanEnhanceKind.auto;
      default:
        return ScanEnhanceKind.document;
    }
  }
}
