import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/services/file_service.dart';

final pdfWatermarkServiceProvider =
    Provider<PdfWatermarkService>((ref) => PdfWatermarkService(ref));

class PdfWatermarkOptions {
  const PdfWatermarkOptions({
    this.text = 'CONFIDENTIAL',
    this.opacity = 0.25,
    this.fontSize = 48,
    this.diagonal = true,
  });

  final String text;
  final double opacity;
  final double fontSize;
  final bool diagonal;
}

class PdfWatermarkResult {
  const PdfWatermarkResult({
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

class PdfWatermarkService {
  PdfWatermarkService(this._ref);

  final Ref _ref;

  Future<PdfWatermarkResult> apply({
    required String inputPath,
    required PdfWatermarkOptions options,
    required int pageCount,
  }) async {
    if (options.text.trim().isEmpty) {
      throw const ProcessingException('Watermark text cannot be empty.');
    }

    final file = File(inputPath);
    if (!await file.exists()) {
      throw const InvalidFileException('PDF file no longer exists.');
    }

    final document = PdfDocument(inputBytes: await file.readAsBytes());

    try {
      final alpha = (options.opacity.clamp(0.05, 1.0) * 255).round();
      final brush = PdfSolidBrush(PdfColor(128, 128, 128, alpha));
      final font = PdfStandardFont(PdfFontFamily.helvetica, options.fontSize);

      for (var i = 0; i < document.pages.count; i++) {
        final page = document.pages[i];
        final graphics = page.graphics;
        final size = page.getClientSize();

        if (options.diagonal) {
          graphics.save();
          graphics.translateTransform(size.width / 2, size.height / 2);
          graphics.rotateTransform(-45);
          final textSize = font.measureString(options.text);
          graphics.drawString(
            options.text,
            font,
            brush: brush,
            bounds: Rect.fromCenter(
              center: Offset.zero,
              width: textSize.width,
              height: textSize.height,
            ),
          );
          graphics.restore();
        } else {
          final textSize = font.measureString(options.text);
          graphics.drawString(
            options.text,
            font,
            brush: brush,
            bounds: Rect.fromLTWH(
              (size.width - textSize.width) / 2,
              (size.height - textSize.height) / 2,
              textSize.width,
              textSize.height,
            ),
          );
        }
      }

      final outputBytes = Uint8List.fromList(await document.save());
      final fileName = FilenameGenerator.watermarkedPdf(inputPath);
      final outputPath = await _ref
          .read(fileServiceProvider)
          .saveToOutput(fileName, outputBytes);

      return PdfWatermarkResult(
        outputPath: outputPath,
        fileName: fileName,
        outputSizeBytes: outputBytes.length,
        pageCount: pageCount,
      );
    } finally {
      document.dispose();
    }
  }
}
