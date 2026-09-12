import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/services/file_service.dart';
import '../models/image_export_format.dart';

final pdfToImageServiceProvider =
    Provider<PdfToImageService>((ref) => PdfToImageService(ref));

class PdfToImageResult {
  const PdfToImageResult({
    required this.outputPaths,
    required this.primaryOutputPath,
    required this.primaryFileName,
    required this.totalOutputBytes,
    required this.pageCount,
    required this.format,
    this.zipPath,
    this.zipFileName,
  });

  final List<String> outputPaths;
  final String primaryOutputPath;
  final String primaryFileName;
  final int totalOutputBytes;
  final int pageCount;
  final ImageExportFormat format;
  final String? zipPath;
  final String? zipFileName;

  bool get hasZip => zipPath != null;
  bool get isSingleOutput => outputPaths.length == 1;
}

typedef PdfToImageProgressCallback = void Function(int current, int total);

/// Converts PDF pages to JPG or PNG images on-device.
class PdfToImageService {
  PdfToImageService(this._ref);

  final Ref _ref;

  static const double _dpi = 150;

  Future<PdfToImageResult> convert({
    required String inputPath,
    required List<int> pageNumbers,
    required ImageExportFormat format,
    PdfToImageProgressCallback? onProgress,
  }) async {
    if (pageNumbers.isEmpty) {
      throw const ProcessingException('No pages selected for export.');
    }

    if (!await File(inputPath).exists()) {
      throw const InvalidFileException('PDF file no longer exists.');
    }

    final inputBytes = await File(inputPath).readAsBytes();
    final outputPaths = <String>[];
    var totalBytes = 0;

    for (var i = 0; i < pageNumbers.length; i++) {
      final pageNumber = pageNumbers[i];
      onProgress?.call(i + 1, pageNumbers.length);

      final pageIndex = pageNumber - 1;
      Uint8List? imageBytes;

      await for (final raster in Printing.raster(
        inputBytes,
        pages: [pageIndex],
        dpi: _dpi,
      )) {
        imageBytes = await _encodeRaster(raster, format);
      }

      if (imageBytes == null || imageBytes.isEmpty) {
        throw ProcessingException('Failed to export page $pageNumber.');
      }

      final fileName = FilenameGenerator.pdfPageImage(
        inputPath,
        pageNumber,
        format.extension,
      );
      final fileService = _ref.read(fileServiceProvider);
      final outputPath = await fileService.saveToOutput(fileName, imageBytes);
      outputPaths.add(outputPath);
      totalBytes += imageBytes.length;
    }

    if (outputPaths.length == 1) {
      final file = File(outputPaths.first);
      return PdfToImageResult(
        outputPaths: outputPaths,
        primaryOutputPath: outputPaths.first,
        primaryFileName: file.uri.pathSegments.last,
        totalOutputBytes: totalBytes,
        pageCount: 1,
        format: format,
      );
    }

    final zip = await _createZip(inputPath, outputPaths);
    return PdfToImageResult(
      outputPaths: outputPaths,
      primaryOutputPath: zip.path,
      primaryFileName: zip.fileName,
      totalOutputBytes: totalBytes + zip.sizeBytes,
      pageCount: outputPaths.length,
      format: format,
      zipPath: zip.path,
      zipFileName: zip.fileName,
    );
  }

  Future<Uint8List> _encodeRaster(
    PdfRaster raster,
    ImageExportFormat format,
  ) async {
    if (format == ImageExportFormat.png) {
      return Uint8List.fromList(await raster.toPng());
    }

    final pngBytes = await raster.toPng();
    final decoded = img.decodeImage(pngBytes);
    if (decoded == null) {
      throw const ProcessingException('Failed to process a PDF page.');
    }
    return Uint8List.fromList(
      img.encodeJpg(decoded, quality: format.jpegQuality),
    );
  }

  Future<_ZipResult> _createZip(String inputPath, List<String> filePaths) async {
    final archive = Archive();

    for (final path in filePaths) {
      final file = File(path);
      final bytes = await file.readAsBytes();
      archive.addFile(
        ArchiveFile(file.uri.pathSegments.last, bytes.length, bytes),
      );
    }

    final zipBytes = ZipEncoder().encode(archive);
    final zipFileName = FilenameGenerator.pdfToImageZip(inputPath);
    final fileService = _ref.read(fileServiceProvider);
    final zipPath = await fileService.saveToOutput(zipFileName, zipBytes);

    return _ZipResult(
      path: zipPath,
      fileName: zipFileName,
      sizeBytes: zipBytes.length,
    );
  }
}

class _ZipResult {
  const _ZipResult({
    required this.path,
    required this.fileName,
    required this.sizeBytes,
  });

  final String path;
  final String fileName;
  final int sizeBytes;
}
