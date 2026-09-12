import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';

import '../models/editor_models.dart';

final pdfOcrServiceProvider =
    Provider<PdfOcrService>((ref) => PdfOcrService());

class PdfOcrService {
  static const _uuid = Uuid();
  static const _dpi = 200;

  Future<List<PdfTextObjectMetadata>> recognizePage({
    required Uint8List pdfBytes,
    required int pageIndex,
    required Size pageSize,
  }) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final objects = <PdfTextObjectMetadata>[];

    try {
      Uint8List? pngBytes;
      await for (final raster in Printing.raster(
        pdfBytes,
        pages: [pageIndex],
        dpi: _dpi.toDouble(),
      )) {
        pngBytes = await raster.toPng();
        break;
      }

      if (pngBytes == null) return objects;

      final imagePath = await _writeTempPng(pngBytes);
      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );

      if (recognized.blocks.isEmpty) return objects;

      final imageWidth = recognized.blocks.first.boundingBox.width;
      final imageHeight = recognized.blocks
          .map((b) => b.boundingBox.bottom)
          .fold<double>(0, (a, b) => a > b ? a : b);

      final scaleX = pageSize.width / (imageWidth > 0 ? imageWidth : pageSize.width);
      final scaleY =
          pageSize.height / (imageHeight > 0 ? imageHeight : pageSize.height);

      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          if (line.text.trim().isEmpty) continue;
          final rect = line.boundingBox;
          final pdfBounds = Rect.fromLTWH(
            rect.left * scaleX,
            rect.top * scaleY,
            rect.width * scaleX,
            rect.height * scaleY,
          );

          final estimatedSize = pdfBounds.height * 0.85;

          objects.add(
            PdfTextObjectMetadata(
              id: _uuid.v4(),
              pageIndex: pageIndex,
              originalText: line.text,
              fontName: 'Helvetica',
              fontFamily: 'Helvetica',
              fontSize: estimatedSize.clamp(8, 48),
              fontWeight: 'normal',
              fontStyle: const [],
              color: const Color(0xFF000000),
              characterSpacing: 0,
              lineSpacing: estimatedSize * 0.2,
              alignment: TextAlign.left,
              bounds: pdfBounds,
              rotation: 0,
              isFromOcr: true,
              fontPreserved: false,
              fontNotice:
                  'OCR estimated font appearance. Exact original font cannot be recovered from scans.',
            ),
          );
        }
      }
    } finally {
      await recognizer.close();
    }

    return objects;
  }

  Future<String> _writeTempPng(Uint8List pngBytes) async {
    final dir = await Directory.systemTemp.createTemp('pdf_ocr_');
    final file = File('${dir.path}/page.png');
    await file.writeAsBytes(pngBytes);
    return file.path;
  }
}
