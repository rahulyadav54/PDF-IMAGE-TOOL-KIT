import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/services/file_service.dart';
import '../models/pdf_health_report.dart';

final pdfFixServiceProvider =
    Provider<PdfFixService>((ref) => PdfFixService(ref));

class PdfFixResult {
  const PdfFixResult({
    required this.outputPath,
    required this.fileName,
    required this.outputSizeBytes,
    required this.pageCount,
    required this.fixesApplied,
  });

  final String outputPath;
  final String fileName;
  final int outputSizeBytes;
  final int pageCount;
  final int fixesApplied;
}

typedef PdfFixProgress = void Function(int current, int total);

class PdfFixService {
  PdfFixService(this._ref);

  final Ref _ref;

  Future<PdfFixResult> applyFixes({
    required String inputPath,
    required List<PdfPageIssue> issuesToFix,
    PdfFixProgress? onProgress,
  }) async {
    if (issuesToFix.isEmpty) {
      throw const ProcessingException('No fixes selected.');
    }

    final bytes = await File(inputPath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    var fixesApplied = 0;

    try {
      final rotatedPages = issuesToFix
          .where((i) => i.kind == PdfPageIssueKind.rotated)
          .map((i) => i.pageIndex)
          .toSet();

      for (final pageIndex in rotatedPages) {
        if (pageIndex < 0 || pageIndex >= document.pages.count) continue;
        final page = document.pages[pageIndex];
        if (page.rotation != PdfPageRotateAngle.rotateAngle0) {
          page.rotation = PdfPageRotateAngle.rotateAngle0;
          fixesApplied++;
        }
      }

      final pageCount = document.pages.count;
      onProgress?.call(pageCount, pageCount);

      final outputBytes = Uint8List.fromList(await document.save());
      final fileName = FilenameGenerator.withSuffix(inputPath, 'fixed', newExtension: '.pdf');
      final outputPath =
          await _ref.read(fileServiceProvider).saveToOutput(fileName, outputBytes);

      return PdfFixResult(
        outputPath: outputPath,
        fileName: fileName,
        outputSizeBytes: outputBytes.length,
        pageCount: pageCount,
        fixesApplied: fixesApplied,
      );
    } finally {
      document.dispose();
    }
  }
}
