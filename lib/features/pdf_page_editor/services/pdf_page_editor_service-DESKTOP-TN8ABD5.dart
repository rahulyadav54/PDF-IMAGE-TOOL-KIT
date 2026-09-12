import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/services/file_service.dart';
import '../models/editable_pdf_page.dart';

final pdfPageEditorServiceProvider =
    Provider<PdfPageEditorService>((ref) => PdfPageEditorService(ref));

class PdfPageEditorResult {
  const PdfPageEditorResult({
    required this.outputPath,
    required this.fileName,
    required this.outputSizeBytes,
    required this.pageCount,
  });

  final String outputPath;
  final String fileName;
  final int outputSizeBytes;
  final int pageCount;
}

typedef PageEditorProgressCallback = void Function(int current, int total);

class PdfPageEditorService {
  PdfPageEditorService(this._ref);

  final Ref _ref;

  List<EditablePdfPage> createInitialPages(int pageCount) {
    return List.generate(
      pageCount,
      (index) => EditablePdfPage(originalIndex: index),
    );
  }

  Future<PdfPageEditorResult> export({
    required String inputPath,
    required List<EditablePdfPage> pages,
    PageEditorProgressCallback? onProgress,
  }) async {
    if (pages.isEmpty) {
      throw const ProcessingException('Add at least one page to export.');
    }

    final file = File(inputPath);
    if (!await file.exists()) {
      throw const InvalidFileException('PDF file no longer exists.');
    }

    final sourceBytes = await file.readAsBytes();
    final sourceDocument = PdfDocument(inputBytes: sourceBytes);
    final outputDocument = PdfDocument();
    outputDocument.compressionLevel = PdfCompressionLevel.best;
    outputDocument.fileStructure.incrementalUpdate = false;

    try {
      for (var i = 0; i < pages.length; i++) {
        onProgress?.call(i + 1, pages.length);

        final page = pages[i];
        if (page.originalIndex < 0 ||
            page.originalIndex >= sourceDocument.pages.count) {
          throw const InvalidFileException('Invalid page selection.');
        }

        final sourcePage = sourceDocument.pages[page.originalIndex];
        final template = sourcePage.createTemplate();
        final pageSize = sourcePage.getClientSize();

        outputDocument.pageSettings.size = pageSize;
        final newPage = outputDocument.pages.add();
        newPage.rotation = page.rotationAngle;
        newPage.graphics.drawPdfTemplate(
          template,
          const Offset(0, 0),
          pageSize,
        );
      }

      final outputBytes = Uint8List.fromList(await outputDocument.save());
      final fileName = FilenameGenerator.editedPdf(inputPath);
      final outputPath =
          await _ref.read(fileServiceProvider).saveToOutput(fileName, outputBytes);

      return PdfPageEditorResult(
        outputPath: outputPath,
        fileName: fileName,
        outputSizeBytes: outputBytes.length,
        pageCount: pages.length,
      );
    } finally {
      sourceDocument.dispose();
      outputDocument.dispose();
    }
  }
}
