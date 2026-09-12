import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/services/file_service.dart';
import '../models/compression_level.dart';

final pdfCompressionServiceProvider =
    Provider<PdfCompressionService>((ref) => PdfCompressionService(ref));

class PdfCompressionResult {
  const PdfCompressionResult({
    required this.outputPath,
    required this.fileName,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.pageCount,
    required this.usedRasterize,
  });

  final String outputPath;
  final String fileName;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final int pageCount;
  final bool usedRasterize;

  int? get savedPercent {
    if (compressedSizeBytes >= originalSizeBytes) return 0;
    return (((originalSizeBytes - compressedSizeBytes) / originalSizeBytes) * 100)
        .round();
  }
}

typedef CompressionProgressCallback = void Function(int current, int total);

/// Compresses PDFs on-device using stream optimization or page rasterization.
class PdfCompressionService {
  PdfCompressionService(this._ref);

  final Ref _ref;

  Future<PdfCompressionResult> compress({
    required String inputPath,
    required CompressionLevel level,
    required int pageCount,
    CompressionProgressCallback? onProgress,
  }) async {
    final originalSize = await File(inputPath).length();
    final inputBytes = await File(inputPath).readAsBytes();
    Uint8List compressedBytes;

    if (level.useRasterize) {
      compressedBytes = await _rasterizeCompress(
        inputBytes: inputBytes,
        level: level,
        pageCount: pageCount,
        onProgress: onProgress,
      );
    } else {
      onProgress?.call(1, 1);
      compressedBytes = await _streamCompress(inputBytes);
    }

    if (compressedBytes.isEmpty) {
      throw const ProcessingException('Compression produced an empty file.');
    }

    final fileName = FilenameGenerator.compressed(inputPath);
    final fileService = _ref.read(fileServiceProvider);
    final outputPath = await fileService.saveToOutput(fileName, compressedBytes);

    return PdfCompressionResult(
      outputPath: outputPath,
      fileName: fileName,
      originalSizeBytes: originalSize,
      compressedSizeBytes: compressedBytes.length,
      pageCount: pageCount,
      usedRasterize: level.useRasterize,
    );
  }

  /// Preserves text/vectors by re-saving with stream compression only.
  Future<Uint8List> _streamCompress(List<int> inputBytes) async {
    sf.PdfDocument? document;

    try {
      document = sf.PdfDocument(inputBytes: inputBytes);
      document.compressionLevel = sf.PdfCompressionLevel.best;
      document.fileStructure.incrementalUpdate = false;

      final saved = await document.save();
      return Uint8List.fromList(saved);
    } on Exception catch (e) {
      throw ProcessingException(
        "We couldn't compress this PDF. The file may be corrupted or unsupported.",
        cause: e,
      );
    } finally {
      document?.dispose();
    }
  }

  /// Rasterizes pages to JPEG and rebuilds the PDF for stronger compression.
  Future<Uint8List> _rasterizeCompress({
    required List<int> inputBytes,
    required CompressionLevel level,
    required int pageCount,
    CompressionProgressCallback? onProgress,
  }) async {
    final output = pw.Document();
    final dpi = _dpiForLevel(level);
    final pageIndexes = List.generate(pageCount, (index) => index);

    var current = 0;
    await for (final raster in Printing.raster(
      Uint8List.fromList(inputBytes),
      pages: pageIndexes,
      dpi: dpi,
    )) {
      current++;
      onProgress?.call(current, pageCount);

      final pngBytes = await raster.toPng();
      final decoded = img.decodeImage(pngBytes);
      if (decoded == null) {
        throw const ProcessingException('Failed to process a PDF page.');
      }

      final jpegBytes = img.encodeJpg(decoded, quality: level.jpegQuality);
      final pageFormat = PdfPageFormat(
        raster.width * PdfPageFormat.inch / dpi,
        raster.height * PdfPageFormat.inch / dpi,
      );
      final image = pw.MemoryImage(Uint8List.fromList(jpegBytes));

      output.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }

    if (current == 0) {
      throw const InvalidFileException('This PDF has no renderable pages.');
    }

    return Uint8List.fromList(await output.save());
  }

  double _dpiForLevel(CompressionLevel level) {
    switch (level) {
      case CompressionLevel.low:
        return 96;
      case CompressionLevel.medium:
        return 120;
      case CompressionLevel.high:
        return 150;
    }
  }
}
