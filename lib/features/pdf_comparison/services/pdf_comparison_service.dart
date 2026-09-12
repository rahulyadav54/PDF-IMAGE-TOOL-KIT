import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

final pdfComparisonServiceProvider =
    Provider<PdfComparisonService>((ref) => const PdfComparisonService());

enum PdfPageDiffKind {
  unchanged,
  modified,
  added,
  removed,
}

class PdfPageDiff {
  const PdfPageDiff({
    required this.pageNumber,
    required this.kind,
    this.textChanges = const [],
    this.visualDifferencePercent,
  });

  final int pageNumber;
  final PdfPageDiffKind kind;
  final List<String> textChanges;
  final double? visualDifferencePercent;
}

class PdfComparisonReport {
  const PdfComparisonReport({
    required this.originalPageCount,
    required this.modifiedPageCount,
    required this.pageDiffs,
  });

  final int originalPageCount;
  final int modifiedPageCount;
  final List<PdfPageDiff> pageDiffs;

  int get modifiedCount =>
      pageDiffs.where((d) => d.kind == PdfPageDiffKind.modified).length;
}

class PdfComparisonService {
  const PdfComparisonService();

  Future<PdfComparisonReport> compare({
    required String originalPath,
    required String modifiedPath,
    void Function(int current, int total)? onProgress,
  }) async {
    final originalBytes = await File(originalPath).readAsBytes();
    final modifiedBytes = await File(modifiedPath).readAsBytes();
    final original = PdfDocument(inputBytes: originalBytes);
    final modified = PdfDocument(inputBytes: modifiedBytes);

    try {
      final originalCount = original.pages.count;
      final modifiedCount = modified.pages.count;
      final maxPages = originalCount > modifiedCount ? originalCount : modifiedCount;
      final diffs = <PdfPageDiff>[];

      for (var i = 0; i < maxPages; i++) {
        onProgress?.call(i + 1, maxPages);

        if (i >= originalCount) {
          diffs.add(PdfPageDiff(pageNumber: i + 1, kind: PdfPageDiffKind.added));
          continue;
        }
        if (i >= modifiedCount) {
          diffs.add(PdfPageDiff(pageNumber: i + 1, kind: PdfPageDiffKind.removed));
          continue;
        }

        final originalText = PdfTextExtractor(original)
            .extractText(startPageIndex: i, endPageIndex: i)
            .trim();
        final modifiedText = PdfTextExtractor(modified)
            .extractText(startPageIndex: i, endPageIndex: i)
            .trim();

        final textChanges = <String>[];
        if (originalText != modifiedText) {
          if (modifiedText.isNotEmpty && !originalText.contains(modifiedText)) {
            textChanges.add('Text changed on page ${i + 1}');
          }
        }

        final visualDiff = await _visualDifferencePercent(
          originalBytes,
          modifiedBytes,
          i,
        );

        final kind = originalText == modifiedText && (visualDiff ?? 0) < 2
            ? PdfPageDiffKind.unchanged
            : PdfPageDiffKind.modified;

        diffs.add(
          PdfPageDiff(
            pageNumber: i + 1,
            kind: kind,
            textChanges: textChanges,
            visualDifferencePercent: visualDiff,
          ),
        );
      }

      return PdfComparisonReport(
        originalPageCount: originalCount,
        modifiedPageCount: modifiedCount,
        pageDiffs: diffs,
      );
    } finally {
      original.dispose();
      modified.dispose();
    }
  }

  Future<double?> _visualDifferencePercent(
    Uint8List originalBytes,
    Uint8List modifiedBytes,
    int pageIndex,
  ) async {
    final a = await _pagePng(originalBytes, pageIndex);
    final b = await _pagePng(modifiedBytes, pageIndex);
    if (a == null || b == null) return null;
    if (a.length != b.length) return 100;

    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > 12) diff++;
    }
    return (diff / a.length) * 100;
  }

  Future<Uint8List?> _pagePng(Uint8List bytes, int pageIndex) async {
    await for (final raster in Printing.raster(bytes, pages: [pageIndex], dpi: 48)) {
      return await raster.toPng();
    }
    return null;
  }
}
