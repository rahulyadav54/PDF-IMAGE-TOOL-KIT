import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/services/bulk_processing/cancel_token.dart';
import '../../../shared/services/file_service.dart';
import '../../../shared/services/document_processing/pdf_page_layout.dart';
import '../models/pdf_page_config.dart';
import 'image_to_pdf_isolate.dart';

final imageToPdfServiceProvider =
    Provider<ImageToPdfService>((ref) => ImageToPdfService(ref));

class ImageToPdfResult {
  const ImageToPdfResult({
    required this.outputPath,
    required this.fileName,
    required this.pageCount,
    required this.fileSizeBytes,
    this.failedPaths = const [],
  });

  final String outputPath;
  final String fileName;
  final int pageCount;
  final int fileSizeBytes;
  final List<String> failedPaths;
}

typedef ImageToPdfProgressCallback = void Function(int current, int total);

/// Converts multiple images into a single PDF on-device.
class ImageToPdfService {
  ImageToPdfService(this._ref);

  final Ref _ref;

  Future<ImageToPdfResult> generate({
    required List<String> imagePaths,
    required PdfPageConfig config,
    int maxWidth = 2200,
    int jpegQuality = 88,
    Set<String> preprocessedPaths = const {},
    ImageToPdfProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (imagePaths.isEmpty) {
      throw const ProcessingException(
        'Add at least one image before creating a PDF.',
      );
    }

    final pdf = pw.Document();
    final failedPaths = <String>[];
    var pageCount = 0;

    for (var i = 0; i < imagePaths.length; i++) {
      cancelToken?.throwIfCancelled();
      onProgress?.call(i + 1, imagePaths.length);

      final path = imagePaths[i];
      if (!await File(path).exists()) {
        failedPaths.add(path);
        continue;
      }

      try {
        final prepared = preprocessedPaths.contains(path)
            ? await _loadPreparedImage(path)
            : await _prepareImage(
                path,
                maxWidth: maxWidth,
                jpegQuality: jpegQuality,
              );
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
        pageCount++;
      } catch (_) {
        failedPaths.add(path);
      }
    }

    if (pageCount == 0) {
      throw const ProcessingException(
        'None of the selected images could be processed.',
      );
    }

    cancelToken?.throwIfCancelled();
    final pdfBytes = await pdf.save();
    final fileName = FilenameGenerator.imageToPdf();
    final fileService = _ref.read(fileServiceProvider);
    final outputPath = await fileService.saveToOutput(fileName, pdfBytes);

    return ImageToPdfResult(
      outputPath: outputPath,
      fileName: fileName,
      pageCount: pageCount,
      fileSizeBytes: pdfBytes.length,
      failedPaths: failedPaths,
    );
  }

  Future<_PreparedImage> _loadPreparedImage(String path) async {
    final rawBytes = await File(path).readAsBytes();
    final prepared = await compute(loadPreparedJpegPage, rawBytes);
    return _PreparedImage(
      bytes: prepared.bytes,
      width: prepared.width,
      height: prepared.height,
    );
  }

  Future<_PreparedImage> _prepareImage(
    String path, {
    required int maxWidth,
    required int jpegQuality,
  }) async {
    final rawBytes = await File(path).readAsBytes();
    final prepared = await compute(
      preparePdfPageInIsolate,
      PreparePdfPageParams(
        bytes: rawBytes,
        maxWidth: maxWidth,
        jpegQuality: jpegQuality,
      ),
    );

    return _PreparedImage(
      bytes: prepared.bytes,
      width: prepared.width,
      height: prepared.height,
    );
  }
}

class _PreparedImage {
  const _PreparedImage({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}
