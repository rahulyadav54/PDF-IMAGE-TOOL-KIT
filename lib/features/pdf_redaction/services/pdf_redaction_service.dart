import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/services/file_service.dart';

final pdfRedactionServiceProvider =
    Provider<PdfRedactionService>((ref) => PdfRedactionService(ref));

class SensitiveMatch {
  const SensitiveMatch({
    required this.id,
    required this.pageIndex,
    required this.label,
    required this.text,
    required this.bounds,
    required this.pattern,
    this.selected = true,
  });

  final String id;
  final int pageIndex;
  final String label;
  final String text;
  final Rect bounds;
  final String pattern;
  final bool selected;

  SensitiveMatch copyWith({bool? selected}) => SensitiveMatch(
        id: id,
        pageIndex: pageIndex,
        label: label,
        text: text,
        bounds: bounds,
        pattern: pattern,
        selected: selected ?? this.selected,
      );
}

class PdfRedactionResult {
  const PdfRedactionResult({
    required this.outputPath,
    required this.fileName,
    required this.redactedCount,
    required this.usedRasterization,
  });

  final String outputPath;
  final String fileName;
  final int redactedCount;
  final bool usedRasterization;
}

class PdfRedactionService {
  PdfRedactionService(this._ref);

  final Ref _ref;

  static final _patterns = <String, RegExp>{
    'Phone': RegExp(
      r'(\+?\d{1,3}[\s-]?)?(\(?\d{2,4}\)?[\s-]?)?\d{3,4}[\s-]?\d{3,4}',
    ),
    'Email': RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'),
    'ID number': RegExp(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b'),
    'Account': RegExp(r'\b\d{8,16}\b'),
    'Date': RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b'),
  };

  Future<List<SensitiveMatch>> detectSensitiveInfo(String inputPath) async {
    final bytes = await File(inputPath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final matches = <SensitiveMatch>[];
    var counter = 0;

    try {
      final extractor = PdfTextExtractor(document);
      final lines = extractor.extractTextLines();

      for (final line in lines) {
        for (final entry in _patterns.entries) {
          for (final match in entry.value.allMatches(line.text)) {
            final text = match.group(0) ?? '';
            if (text.trim().length < 4) continue;
            matches.add(
              SensitiveMatch(
                id: 'match_${counter++}',
                pageIndex: line.pageIndex,
                label: entry.key,
                text: text,
                bounds: line.bounds,
                pattern: entry.key,
              ),
            );
          }
        }
      }
    } finally {
      document.dispose();
    }

    return matches;
  }

  Future<PdfRedactionResult> applyRedactions({
    required String inputPath,
    required List<SensitiveMatch> matches,
    bool rasterizePages = true,
    void Function(int current, int total)? onProgress,
  }) async {
    final selected = matches.where((m) => m.selected).toList();
    if (selected.isEmpty) {
      throw const ProcessingException('Select at least one item to redact.');
    }

    final bytes = await File(inputPath).readAsBytes();
    final source = PdfDocument(inputBytes: bytes);
    final output = PdfDocument();
    output.compressionLevel = PdfCompressionLevel.best;

    try {
      final pageCount = source.pages.count;
      for (var i = 0; i < pageCount; i++) {
        onProgress?.call(i + 1, pageCount);
        final sourcePage = source.pages[i];
        final pageSize = sourcePage.getClientSize();
        output.pageSettings.size = pageSize;
        final targetPage = output.pages.add();
        final pageMatches =
            selected.where((m) => m.pageIndex == i).toList(growable: false);

        if (rasterizePages && pageMatches.isNotEmpty) {
          final raster = await _rasterizePage(bytes, i);
          if (raster != null) {
            for (final match in pageMatches) {
              _paintBlackBox(raster, match.bounds, pageSize);
            }
            final bitmap = PdfBitmap(
              Uint8List.fromList(img.encodeJpg(raster, quality: 92)),
            );
            targetPage.graphics.drawImage(bitmap, Rect.fromLTWH(0, 0, pageSize.width, pageSize.height));
            continue;
          }
        }

        final template = sourcePage.createTemplate();
        targetPage.graphics.drawPdfTemplate(template, Offset.zero, pageSize);
        for (final match in pageMatches) {
          final expanded = match.bounds.inflate(2);
          targetPage.graphics.drawRectangle(
            brush: PdfBrushes.white,
            bounds: expanded,
          );
          targetPage.graphics.drawRectangle(
            brush: PdfSolidBrush(PdfColor(0, 0, 0)),
            bounds: expanded,
          );
        }
      }

      final outputBytes = Uint8List.fromList(await output.save());
      final fileName =
          FilenameGenerator.withSuffix(inputPath, 'redacted', newExtension: '.pdf');
      final outputPath =
          await _ref.read(fileServiceProvider).saveToOutput(fileName, outputBytes);

      return PdfRedactionResult(
        outputPath: outputPath,
        fileName: fileName,
        redactedCount: selected.length,
        usedRasterization: rasterizePages,
      );
    } finally {
      source.dispose();
      output.dispose();
    }
  }

  Future<img.Image?> _rasterizePage(Uint8List pdfBytes, int pageIndex) async {
    Uint8List? pngBytes;
    await for (final raster in Printing.raster(
      pdfBytes,
      pages: [pageIndex],
      dpi: 150,
    )) {
      pngBytes = await raster.toPng();
      break;
    }
    if (pngBytes == null) return null;
    return img.decodeImage(pngBytes);
  }

  void _paintBlackBox(img.Image image, Rect bounds, Size pageSize) {
    final scaleX = image.width / pageSize.width;
    final scaleY = image.height / pageSize.height;
    final left = (bounds.left * scaleX).round().clamp(0, image.width - 1);
    final top = (bounds.top * scaleY).round().clamp(0, image.height - 1);
    final right = (bounds.right * scaleX).round().clamp(left + 1, image.width);
    final bottom = (bounds.bottom * scaleY).round().clamp(top + 1, image.height);
    img.fillRect(image, x1: left, y1: top, x2: right, y2: bottom, color: img.ColorRgb8(0, 0, 0));
  }
}
