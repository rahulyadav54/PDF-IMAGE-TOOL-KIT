import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/services/file_service.dart';
import '../utils/page_range_validator.dart';

final pdfSplitServiceProvider = Provider<PdfSplitService>((ref) => PdfSplitService(ref));

class PdfSplitResult {
  const PdfSplitResult({
    required this.outputPaths,
    required this.primaryOutputPath,
    required this.primaryFileName,
    required this.totalOutputBytes,
    this.zipPath,
    this.zipFileName,
  });

  final List<String> outputPaths;
  final String primaryOutputPath;
  final String primaryFileName;
  final int totalOutputBytes;
  final String? zipPath;
  final String? zipFileName;

  bool get hasZip => zipPath != null;
  int get fileCount => outputPaths.length;
}

typedef SplitProgressCallback = void Function(int current, int total);

/// Splits PDFs on-device by page range or into individual page files.
class PdfSplitService {
  PdfSplitService(this._ref);

  final Ref _ref;

  Future<PdfSplitResult> extractRange({
    required String inputPath,
    required int startPage,
    required int endPage,
    required int totalPages,
    SplitProgressCallback? onProgress,
  }) async {
    final error = PageRangeValidator.validate(startPage, endPage, totalPages);
    if (error != null) throw ProcessingException(error);

    final indices = PageRangeValidator.toPageIndices(startPage, endPage);
    onProgress?.call(1, 1);

    final bytes = await _extractPages(inputPath, indices);
    final fileName = FilenameGenerator.extractedRange(inputPath, startPage, endPage);
    final fileService = _ref.read(fileServiceProvider);
    final outputPath = await fileService.saveToOutput(fileName, bytes);

    return PdfSplitResult(
      outputPaths: [outputPath],
      primaryOutputPath: outputPath,
      primaryFileName: fileName,
      totalOutputBytes: bytes.length,
    );
  }

  Future<PdfSplitResult> splitEveryPage({
    required String inputPath,
    required int totalPages,
    SplitProgressCallback? onProgress,
  }) async {
    if (totalPages <= 0) {
      throw const ProcessingException('This PDF has no pages to split.');
    }

    final outputPaths = <String>[];
    var totalBytes = 0;
    final sourceBytes = await File(inputPath).readAsBytes();
    final sourceDocument = PdfDocument(inputBytes: sourceBytes);

    try {
      for (var page = 1; page <= totalPages; page++) {
        onProgress?.call(page, totalPages);

        final pageBytes = await _extractPagesFromDocument(
          sourceDocument,
          [page - 1],
        );
        final fileName = FilenameGenerator.splitPage(inputPath, page);
        final fileService = _ref.read(fileServiceProvider);
        final outputPath = await fileService.saveToOutput(fileName, pageBytes);
        outputPaths.add(outputPath);
        totalBytes += pageBytes.length;
      }
    } finally {
      sourceDocument.dispose();
    }

    final zipResult = await _createZip(inputPath, outputPaths);

    return PdfSplitResult(
      outputPaths: outputPaths,
      primaryOutputPath: zipResult.path,
      primaryFileName: zipResult.fileName,
      totalOutputBytes: totalBytes + zipResult.sizeBytes,
      zipPath: zipResult.path,
      zipFileName: zipResult.fileName,
    );
  }

  Future<Uint8List> _extractPages(String inputPath, List<int> pageIndices) async {
    final sourceBytes = await File(inputPath).readAsBytes();
    final sourceDocument = PdfDocument(inputBytes: sourceBytes);
    try {
      return await _extractPagesFromDocument(sourceDocument, pageIndices);
    } finally {
      sourceDocument.dispose();
    }
  }

  Future<Uint8List> _extractPagesFromDocument(
    PdfDocument sourceDocument,
    List<int> pageIndices,
  ) async {
    final outputDocument = PdfDocument();
    outputDocument.compressionLevel = PdfCompressionLevel.best;
    outputDocument.fileStructure.incrementalUpdate = false;

    try {
      for (final index in pageIndices) {
        if (index < 0 || index >= sourceDocument.pages.count) {
          throw const InvalidFileException('Invalid page range for this PDF.');
        }

        final sourcePage = sourceDocument.pages[index];
        final template = sourcePage.createTemplate();
        final pageSize = sourcePage.getClientSize();

        outputDocument.pageSettings.size = pageSize;
        final newPage = outputDocument.pages.add();
        newPage.graphics.drawPdfTemplate(
          template,
          const Offset(0, 0),
          pageSize,
        );
      }

      return Uint8List.fromList(await outputDocument.save());
    } finally {
      outputDocument.dispose();
    }
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

    final zipFileName = FilenameGenerator.splitZip(inputPath);
    final fileService = _ref.read(fileServiceProvider);
    final zipPath = await fileService.saveToOutput(zipFileName, zipBytes);

    return _ZipResult(path: zipPath, fileName: zipFileName, sizeBytes: zipBytes.length);
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
