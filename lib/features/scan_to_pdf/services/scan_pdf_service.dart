import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../features/image_to_pdf/models/pdf_page_config.dart';
import '../../../shared/services/document_processing/pdf_page_layout.dart';
import '../../../shared/services/file_service.dart';
import '../../image_to_pdf/services/image_to_pdf_isolate.dart';

final scanPdfServiceProvider = Provider<ScanPdfService>((ref) => ScanPdfService(ref));

/// Generates a multi-page PDF from scanned images with memory-safe resizing.
class ScanPdfService {
  ScanPdfService(this._ref);

  final Ref _ref;

  Future<ScanPdfResult> generatePdf(
    List<String> imagePaths, {
    int maxImageWidth = 1654,
    int jpegQuality = 88,
    PdfPageConfig config = const PdfPageConfig(),
  }) async {
    if (imagePaths.isEmpty) {
      throw const ProcessingException('Add at least one page before generating a PDF.');
    }

    final pdf = pw.Document();

    for (var i = 0; i < imagePaths.length; i++) {
      final path = imagePaths[i];
      if (!await File(path).exists()) {
        throw const InvalidFileException('A scanned page is no longer available.');
      }

      final prepared = await _preparePage(path, maxImageWidth, jpegQuality);
      final layout = PdfPageLayout.resolve(
        config: config,
        imageWidth: prepared.width,
        imageHeight: prepared.height,
      );
      final image = pw.MemoryImage(prepared.bytes);

      pdf.addPage(
        pw.Page(
          pageFormat: layout.format,
          margin: layout.margins,
          build: (context) => pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }

    final pdfBytes = await pdf.save();
    final fileName = FilenameGenerator.scanned();
    final fileService = _ref.read(fileServiceProvider);
    final outputPath = await fileService.saveToOutput(fileName, pdfBytes);
    final fileSize = await fileService.getFileSize(outputPath);

    return ScanPdfResult(
      outputPath: outputPath,
      fileName: fileName,
      pageCount: imagePaths.length,
      fileSizeBytes: fileSize,
    );
  }

  Future<PreparedPdfPageData> _preparePage(
    String path,
    int maxImageWidth,
    int jpegQuality,
  ) async {
    final rawBytes = await File(path).readAsBytes();
    return compute(
      preparePdfPageInIsolate,
      PreparePdfPageParams(
        bytes: rawBytes,
        maxWidth: maxImageWidth,
        jpegQuality: jpegQuality,
      ),
    );
  }
}

class ScanPdfResult {
  const ScanPdfResult({
    required this.outputPath,
    required this.fileName,
    required this.pageCount,
    required this.fileSizeBytes,
  });

  final String outputPath;
  final String fileName;
  final int pageCount;
  final int fileSizeBytes;
}
