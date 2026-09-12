import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/services/file_service.dart';

final scanPdfServiceProvider = Provider<ScanPdfService>((ref) => ScanPdfService(ref));

/// Generates a multi-page PDF from scanned images with memory-safe resizing.
class ScanPdfService {
  ScanPdfService(this._ref);

  final Ref _ref;

  Future<ScanPdfResult> generatePdf(
    List<String> imagePaths, {
    int maxImageWidth = 1654,
    int jpegQuality = 88,
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

      final bytes = await _preparePageBytes(
        path,
        maxImageWidth: maxImageWidth,
        jpegQuality: jpegQuality,
      );
      final image = pw.MemoryImage(Uint8List.fromList(bytes));

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
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

  Future<List<int>> _preparePageBytes(
    String path, {
    required int maxImageWidth,
    required int jpegQuality,
  }) async {
    final rawBytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      throw const InvalidFileException('Unable to process a scanned page.');
    }

    final resized = decoded.width > maxImageWidth
        ? img.copyResize(decoded, width: maxImageWidth)
        : decoded;

    return img.encodeJpg(resized, quality: jpegQuality.clamp(70, 95));
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
