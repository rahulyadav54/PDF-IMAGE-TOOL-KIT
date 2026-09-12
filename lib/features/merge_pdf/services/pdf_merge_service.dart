import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/services/file_service.dart';
import '../models/merge_pdf_item.dart';

final pdfMergeServiceProvider = Provider<PdfMergeService>((ref) => PdfMergeService(ref));

class PdfMergeResult {
  const PdfMergeResult({
    required this.outputPath,
    required this.fileName,
    required this.pageCount,
    required this.fileSizeBytes,
    required this.sourceFileCount,
  });

  final String outputPath;
  final String fileName;
  final int pageCount;
  final int fileSizeBytes;
  final int sourceFileCount;
}

typedef MergeProgressCallback = void Function(int current, int total);

/// Merges multiple PDF files into one document on-device.
class PdfMergeService {
  PdfMergeService(this._ref);

  final Ref _ref;

  Future<PdfMergeResult> merge({
    required List<MergePdfItem> items,
    MergeProgressCallback? onProgress,
  }) async {
    if (items.length < 2) {
      throw const ProcessingException('Select at least two PDF files to merge.');
    }

    final mergedDocument = PdfDocument();
    mergedDocument.compressionLevel = PdfCompressionLevel.best;
    mergedDocument.fileStructure.incrementalUpdate = false;

    var processedFiles = 0;
    var totalPages = 0;

    try {
      for (final item in items) {
        processedFiles++;
        onProgress?.call(processedFiles, items.length);

        if (!await File(item.filePath).exists()) {
          throw InvalidFileException('${item.fileName} is no longer available.');
        }

        final sourceBytes = await File(item.filePath).readAsBytes();
        final sourceDocument = PdfDocument(inputBytes: sourceBytes);

        try {
          for (var i = 0; i < sourceDocument.pages.count; i++) {
            final sourcePage = sourceDocument.pages[i];
            final template = sourcePage.createTemplate();
            final pageSize = sourcePage.getClientSize();

            mergedDocument.pageSettings.size = pageSize;
            final newPage = mergedDocument.pages.add();
            newPage.graphics.drawPdfTemplate(
              template,
              const Offset(0, 0),
              pageSize,
            );
            totalPages++;
          }
        } finally {
          sourceDocument.dispose();
        }
      }

      if (totalPages == 0) {
        throw const ProcessingException('No pages were found to merge.');
      }

      final outputBytes = Uint8List.fromList(await mergedDocument.save());
      final baseName = items.first.fileName;
      final fileName = FilenameGenerator.merged(baseName);
      final fileService = _ref.read(fileServiceProvider);
      final outputPath = await fileService.saveToOutput(fileName, outputBytes);

      return PdfMergeResult(
        outputPath: outputPath,
        fileName: fileName,
        pageCount: totalPages,
        fileSizeBytes: outputBytes.length,
        sourceFileCount: items.length,
      );
    } on AppException {
      rethrow;
    } on Exception catch (e) {
      throw ProcessingException(
        'Unable to merge these PDF files. One or more files may be invalid.',
        cause: e,
      );
    } finally {
      mergedDocument.dispose();
    }
  }
}
