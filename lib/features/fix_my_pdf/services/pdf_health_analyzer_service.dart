import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/pdf_health_report.dart';

final pdfHealthAnalyzerServiceProvider =
    Provider<PdfHealthAnalyzerService>((ref) => const PdfHealthAnalyzerService());

typedef HealthAnalyzeProgress = void Function(int current, int total);

class PdfHealthAnalyzerService {
  const PdfHealthAnalyzerService();

  Future<PdfHealthReport> analyze({
    required String inputPath,
    HealthAnalyzeProgress? onProgress,
  }) async {
    final bytes = await File(inputPath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    final issues = <PdfPageIssue>[];
    var goodPages = 0;
    Size? referenceSize;

    try {
      final pageCount = document.pages.count;
      for (var i = 0; i < pageCount; i++) {
        onProgress?.call(i + 1, pageCount);
        final page = document.pages[i];
        final size = page.getClientSize();
        final pageIssues = <PdfPageIssue>[];

        if (page.rotation != PdfPageRotateAngle.rotateAngle0) {
          pageIssues.add(
            PdfPageIssue(
              pageIndex: i,
              kind: PdfPageIssueKind.rotated,
              message: 'Page ${i + 1} is rotated',
            ),
          );
        }

        final text = extractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        ).trim();
        if (text.isEmpty) {
          pageIssues.add(
            PdfPageIssue(
              pageIndex: i,
              kind: PdfPageIssueKind.scanned,
              message: 'Page ${i + 1} appears scanned',
              fixable: false,
            ),
          );
        }

        if (referenceSize == null) {
          referenceSize = size;
        } else if ((referenceSize.width - size.width).abs() > 8 ||
            (referenceSize.height - size.height).abs() > 8) {
          pageIssues.add(
            PdfPageIssue(
              pageIndex: i,
              kind: PdfPageIssueKind.mixedPageSize,
              message: 'Page ${i + 1} has different dimensions',
              fixable: false,
            ),
          );
        }

        final rasterStats = await _analyzeRaster(bytes, i);
        if (rasterStats != null) {
          if (rasterStats.isBlank) {
            pageIssues.add(
              PdfPageIssue(
                pageIndex: i,
                kind: PdfPageIssueKind.blank,
                message: 'Page ${i + 1} is mostly blank',
                fixable: false,
              ),
            );
          }
          if (rasterStats.lowContrast) {
            pageIssues.add(
              PdfPageIssue(
                pageIndex: i,
                kind: PdfPageIssueKind.lowContrast,
                message: 'Page ${i + 1} has low contrast',
              ),
            );
          }
          if (rasterStats.blurry) {
            pageIssues.add(
              PdfPageIssue(
                pageIndex: i,
                kind: PdfPageIssueKind.blurry,
                message: 'Page ${i + 1} appears blurry',
                fixable: false,
              ),
            );
          }
          if (rasterStats.largeBorders) {
            pageIssues.add(
              PdfPageIssue(
                pageIndex: i,
                kind: PdfPageIssueKind.largeBorders,
                message: 'Page ${i + 1} has large borders',
              ),
            );
          }
        }

        if (pageIssues.isEmpty) {
          goodPages++;
        } else {
          issues.addAll(pageIssues);
        }
      }
      return PdfHealthReport(
        pageCount: pageCount,
        issues: issues,
        goodPageCount: goodPages,
      );
    } finally {
      document.dispose();
    }
  }

  Future<_RasterStats?> _analyzeRaster(Uint8List pdfBytes, int pageIndex) async {
    Uint8List? pngBytes;
    await for (final raster in Printing.raster(
      pdfBytes,
      pages: [pageIndex],
      dpi: 72,
    )) {
      pngBytes = await raster.toPng();
      break;
    }
    if (pngBytes == null) return null;

    final decoded = img.decodeImage(pngBytes);
    if (decoded == null) return null;

    final sample = img.copyResize(decoded, width: 200);
    var sum = 0.0;
    var count = 0;
    var dark = 0;
    var light = 0;
    for (final pixel in sample) {
      final l = img.getLuminance(pixel);
      sum += l;
      count++;
      if (l < 40) dark++;
      if (l > 220) light++;
    }
    final mean = count == 0 ? 0.0 : sum / count;
    final lowContrast = mean > 90 && mean < 170 && (dark / count) < 0.05;
    final largeBorders = light / count > 0.55;
    final isBlank = light / count > 0.92;
    final blurry = _estimateBlur(sample) < 0.08;

    return _RasterStats(
      lowContrast: lowContrast,
      largeBorders: largeBorders,
      isBlank: isBlank,
      blurry: blurry,
    );
  }

  double _estimateBlur(img.Image source) {
    final gray = img.grayscale(source);
    var laplacian = 0.0;
    var count = 0;
    for (var y = 1; y < gray.height - 1; y++) {
      for (var x = 1; x < gray.width - 1; x++) {
        final c = gray.getPixel(x, y).r;
        final neighbors = gray.getPixel(x - 1, y).r +
            gray.getPixel(x + 1, y).r +
            gray.getPixel(x, y - 1).r +
            gray.getPixel(x, y + 1).r;
        laplacian += (4 * c - neighbors).abs();
        count++;
      }
    }
    if (count == 0) return 0;
    return (laplacian / count / 255).clamp(0.0, 1.0);
  }
}

class _RasterStats {
  const _RasterStats({
    required this.lowContrast,
    required this.largeBorders,
    required this.isBlank,
    required this.blurry,
  });

  final bool lowContrast;
  final bool largeBorders;
  final bool isBlank;
  final bool blurry;
}
