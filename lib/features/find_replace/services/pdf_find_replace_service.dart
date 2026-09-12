import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/utils/filename_generator.dart';
import '../../../features/pdf_editor/services/pdf_document_font_cache.dart';
import '../../../features/pdf_editor/utils/pdf_coordinates.dart';
import '../../../shared/services/file_service.dart';

final pdfFindReplaceServiceProvider =
    Provider<PdfFindReplaceService>((ref) => PdfFindReplaceService(ref));

class PdfTextMatch {
  const PdfTextMatch({
    required this.pageIndex,
    required this.text,
    required this.bounds,
    required this.context,
  });

  final int pageIndex;
  final String text;
  final Rect bounds;
  final String context;
}

class PdfFindReplaceResult {
  const PdfFindReplaceResult({
    required this.outputPath,
    required this.fileName,
    required this.replacementCount,
    required this.fontWarnings,
  });

  final String outputPath;
  final String fileName;
  final int replacementCount;
  final List<String> fontWarnings;
}

class PdfReplaceValidation {
  const PdfReplaceValidation({
    required this.canFit,
    required this.message,
  });

  final bool canFit;
  final String message;
}

class PdfFindReplaceService {
  PdfFindReplaceService(this._ref);

  final Ref _ref;

  Future<List<PdfTextMatch>> findAll({
    required String inputPath,
    required String query,
  }) async {
    if (query.trim().isEmpty) return [];

    final bytes = await File(inputPath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      final matches = PdfTextExtractor(document).findText([query]);
      return matches
          .map(
            (m) => PdfTextMatch(
              pageIndex: m.pageIndex,
              text: m.text,
              bounds: m.bounds,
              context: m.text,
            ),
          )
          .toList();
    } finally {
      document.dispose();
    }
  }

  Future<PdfReplaceValidation> validateReplacement({
    required String inputPath,
    required PdfTextMatch match,
    required String replacement,
  }) async {
    final bytes = await File(inputPath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      final resolver = PdfDocumentFontCache(document);
      final lines = PdfTextExtractor(document).extractTextLines(
        startPageIndex: match.pageIndex,
        endPageIndex: match.pageIndex,
      );
      final line = lines.firstWhere(
        (l) => l.bounds.overlaps(match.bounds.inflate(2)),
        orElse: () => lines.first,
      );
      final font = resolver
          .resolve(
            fontName: line.fontName,
            fontSize: line.fontSize,
            styles: line.fontStyle,
          )
          .font;
      final originalWidth = font.measureString(match.text).width;
      final newWidth = font.measureString(replacement).width;
      if (newWidth > match.bounds.width && newWidth > originalWidth * 1.15) {
        return const PdfReplaceValidation(
          canFit: false,
          message: 'Replacement text is longer than the original.',
        );
      }
      return const PdfReplaceValidation(canFit: true, message: '');
    } finally {
      document.dispose();
    }
  }

  Future<PdfFindReplaceResult> replaceAll({
    required String inputPath,
    required String query,
    required String replacement,
    TextOverflowFitMode fitMode = TextOverflowFitMode.keepSize,
    void Function(int current, int total)? onProgress,
  }) async {
    final bytes = await File(inputPath).readAsBytes();
    final source = PdfDocument(inputBytes: bytes);
    final output = PdfDocument();
    output.compressionLevel = PdfCompressionLevel.best;
    final warnings = <String>{};
    var replacementCount = 0;

    try {
      final matches =
          PdfTextExtractor(source).findText([query]).toList(growable: false);
      final pageCount = source.pages.count;

      for (var i = 0; i < pageCount; i++) {
        onProgress?.call(i + 1, pageCount);
        final sourcePage = source.pages[i];
        final pageSize = sourcePage.getClientSize();
        output.pageSettings.size = pageSize;
        final targetPage = output.pages.add();
        targetPage.rotation = sourcePage.rotation;

        final template = sourcePage.createTemplate();
        targetPage.graphics.drawPdfTemplate(template, Offset.zero, pageSize);

        final pageMatches =
            matches.where((m) => m.pageIndex == i).toList(growable: false);
        if (pageMatches.isEmpty) continue;

        final fontCache = PdfDocumentFontCache(source);
        final lines = PdfTextExtractor(source).extractTextLines(
          startPageIndex: i,
          endPageIndex: i,
        );

        for (final match in pageMatches) {
          final line = lines.firstWhere(
            (l) => l.bounds.overlaps(match.bounds.inflate(2)),
            orElse: () => lines.first,
          );
          final resolution = fontCache.resolve(
            fontName: line.fontName,
            fontSize: line.fontSize,
            styles: line.fontStyle,
          );
          if (resolution.notice != null) warnings.add(resolution.notice!);

          final eraseBounds =
              PdfCoordinates.eraseBounds(match.bounds, fontSize: line.fontSize);
          targetPage.graphics.drawRectangle(
            brush: PdfBrushes.white,
            bounds: eraseBounds,
          );

          var fontSize = line.fontSize;
          if (fitMode == TextOverflowFitMode.fitText) {
            final originalWidth = resolution.font.measureString(match.text).width;
            final newWidth = resolution.font.measureString(replacement).width;
            if (newWidth > match.bounds.width && originalWidth > 0) {
              fontSize *= (match.bounds.width / newWidth).clamp(0.5, 1.0);
            }
          }

          final font = fontCache
              .resolve(
                fontName: line.fontName,
                fontSize: fontSize,
                styles: line.fontStyle,
              )
              .font;

          targetPage.graphics.drawString(
            replacement,
            font,
            bounds: match.bounds,
            brush: PdfSolidBrush(PdfColor(0, 0, 0)),
          );
          replacementCount++;
        }
      }

      final outputBytes = Uint8List.fromList(await output.save());
      final fileName =
          FilenameGenerator.withSuffix(inputPath, 'replaced', newExtension: '.pdf');
      final outputPath =
          await _ref.read(fileServiceProvider).saveToOutput(fileName, outputBytes);

      return PdfFindReplaceResult(
        outputPath: outputPath,
        fileName: fileName,
        replacementCount: replacementCount,
        fontWarnings: warnings.toList(),
      );
    } finally {
      source.dispose();
      output.dispose();
    }
  }
}

enum TextOverflowFitMode {
  keepSize,
  fitText,
}
