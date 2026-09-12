import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../features/pdf_editor/services/pdf_ocr_service.dart';
import '../../../shared/services/file_service.dart';

final pdfExtractTextServiceProvider =
    Provider<PdfExtractTextService>((ref) => PdfExtractTextService(ref));

class ExtractTextResult {
  const ExtractTextResult({
    required this.text,
    required this.outputPath,
    required this.fileName,
    required this.wordCount,
    required this.characterCount,
    required this.usedOcr,
  });

  final String text;
  final String outputPath;
  final String fileName;
  final int wordCount;
  final int characterCount;
  final bool usedOcr;
}

class PdfExtractTextService {
  PdfExtractTextService(this._ref);

  final Ref _ref;

  Future<ExtractTextResult> extract({
    required String inputPath,
    bool useOcrFallback = true,
    void Function(int current, int total)? onProgress,
  }) async {
    final file = File(inputPath);
    if (!await file.exists()) {
      throw const InvalidFileException('PDF file no longer exists.');
    }

    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    var usedOcr = false;
    var text = '';

    try {
      final extractor = PdfTextExtractor(document);
      text = extractor.extractText();

      if (text.trim().isEmpty && useOcrFallback) {
        usedOcr = true;
        final ocr = _ref.read(pdfOcrServiceProvider);
        final pageCount = document.pages.count;
        final buffer = StringBuffer();

        for (var i = 0; i < pageCount; i++) {
          onProgress?.call(i + 1, pageCount);
          final page = document.pages[i];
          final size = Size(page.size.width, page.size.height);
          final objects = await ocr.recognizePage(
            pdfBytes: bytes,
            pageIndex: i,
            pageSize: size,
          );
          if (objects.isNotEmpty) {
            buffer.writeln(objects.map((o) => o.originalText).join('\n'));
            buffer.writeln();
          }
        }
        text = buffer.toString();
      }

      if (text.trim().isEmpty) {
        throw const ProcessingException('No text found in this PDF.');
      }

      final fileName = FilenameGenerator.extractedText(inputPath);
      final outputPath = await _ref.read(fileServiceProvider).saveToOutput(
            fileName,
            Uint8List.fromList(utf8.encode(text)),
          );

      final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);

      return ExtractTextResult(
        text: text,
        outputPath: outputPath,
        fileName: fileName,
        wordCount: words.length,
        characterCount: text.length,
        usedOcr: usedOcr,
      );
    } finally {
      document.dispose();
    }
  }
}
