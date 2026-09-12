import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../features/pdf_editor/services/pdf_ocr_service.dart';
import '../../../shared/services/file_service.dart';

final searchablePdfServiceProvider =
    Provider<SearchablePdfService>((ref) => SearchablePdfService(ref));

class SearchablePdfResult {
  const SearchablePdfResult({
    required this.outputPath,
    required this.fileName,
    required this.outputSizeBytes,
    required this.pageCount,
    required this.textBlocksAdded,
  });

  final String outputPath;
  final String fileName;
  final int outputSizeBytes;
  final int pageCount;
  final int textBlocksAdded;
}

class SearchablePdfService {
  SearchablePdfService(this._ref);

  final Ref _ref;

  Future<SearchablePdfResult> makeSearchable({
    required String inputPath,
    void Function(int current, int total)? onProgress,
  }) async {
    final file = File(inputPath);
    if (!await file.exists()) {
      throw const InvalidFileException('PDF file no longer exists.');
    }

    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final ocr = _ref.read(pdfOcrServiceProvider);
    var textBlocksAdded = 0;

    try {
      final pageCount = document.pages.count;

      for (var i = 0; i < pageCount; i++) {
        onProgress?.call(i + 1, pageCount);
        final page = document.pages[i];
        final size = Size(page.size.width, page.size.height);
        final objects = await ocr.recognizePage(
          pdfBytes: bytes,
          pageIndex: i,
          pageSize: size,
        );

        final graphics = page.graphics;
        for (final obj in objects) {
          if (obj.originalText.trim().isEmpty) continue;
          final fontSize = obj.fontSize.clamp(6.0, 48.0);
          graphics.drawString(
            obj.originalText,
            PdfStandardFont(PdfFontFamily.helvetica, fontSize),
            brush: PdfSolidBrush(PdfColor(0, 0, 0, 0)),
            bounds: obj.bounds,
          );
          textBlocksAdded++;
        }
      }

      if (textBlocksAdded == 0) {
        throw const ProcessingException('No text detected in this PDF.');
      }

      final outputBytes = Uint8List.fromList(await document.save());
      final fileName = FilenameGenerator.searchablePdf(inputPath);
      final outputPath = await _ref
          .read(fileServiceProvider)
          .saveToOutput(fileName, outputBytes);

      return SearchablePdfResult(
        outputPath: outputPath,
        fileName: fileName,
        outputSizeBytes: outputBytes.length,
        pageCount: pageCount,
        textBlocksAdded: textBlocksAdded,
      );
    } finally {
      document.dispose();
    }
  }
}
