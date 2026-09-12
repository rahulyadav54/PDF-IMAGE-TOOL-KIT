import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/services/file_service.dart';
import '../models/editor_models.dart';
import '../utils/pdf_coordinates.dart';
import 'pdf_font_resolver_service.dart';

final pdfEditorExportServiceProvider =
    Provider<PdfEditorExportService>((ref) => PdfEditorExportService(ref));

typedef PdfEditorExportProgress = void Function(int current, int total);

class PdfEditorExportService {
  PdfEditorExportService(this._ref);

  final Ref _ref;
  final PdfFontResolverService _fontResolver = const PdfFontResolverService();

  Future<PdfEditorExportResult> export({
    required String inputPath,
    required Uint8List sourceBytes,
    required List<PdfEditorPage> pages,
    required Map<String, PdfTextObjectMetadata> textObjects,
    required Map<String, PdfTextEdit> textEdits,
    required List<PdfNewTextObject> newTexts,
    required List<PdfImageObject> images,
    required Set<String> deletedImageIds,
    required List<PdfAnnotationObject> annotations,
    required List<PdfSignatureObject> signatures,
    String? password,
    bool saveAsNew = true,
    PdfEditorExportProgress? onProgress,
  }) async {
    if (pages.where((p) => !p.isDeleted).isEmpty) {
      throw const ProcessingException('Add at least one page to export.');
    }

    final warnings = <String>{};
    final sourceDocument = PdfDocument(inputBytes: sourceBytes, password: password);
    final outputDocument = PdfDocument();
    outputDocument.compressionLevel = PdfCompressionLevel.best;

    try {
      final activePages = pages.where((p) => !p.isDeleted).toList();

      for (var i = 0; i < activePages.length; i++) {
        onProgress?.call(i + 1, activePages.length);
        final editorPage = activePages[i];

        PdfPage targetPage;
        Size pageSize;

        if (editorPage.sourceIndex != null &&
            editorPage.sourceIndex! >= 0 &&
            editorPage.sourceIndex! < sourceDocument.pages.count) {
          final sourcePage = sourceDocument.pages[editorPage.sourceIndex!];
          pageSize = sourcePage.getClientSize();
          outputDocument.pageSettings.size = pageSize;
          targetPage = outputDocument.pages.add();
          targetPage.rotation = editorPage.rotationAngle;

          final template = sourcePage.createTemplate();
          targetPage.graphics.drawPdfTemplate(
            template,
            const Offset(0, 0),
            pageSize,
          );
        } else {
          pageSize = const Size(595, 842);
          outputDocument.pageSettings.size = pageSize;
          targetPage = outputDocument.pages.add();
        }

        final pageIndex = i;
        final sourcePageIndex = editorPage.sourceIndex ?? pageIndex;

        _applyTextEdits(
          targetPage,
          sourceDocument,
          sourcePageIndex,
          textEdits,
          warnings,
        );

        _applyNewTexts(targetPage, sourcePageIndex, newTexts);
        _applyImages(targetPage, sourcePageIndex, images, deletedImageIds);
        _applyAnnotations(targetPage, sourcePageIndex, annotations);
        _applySignatures(targetPage, sourcePageIndex, signatures);
      }

      final outputBytes = Uint8List.fromList(await outputDocument.save());
      final fileName = saveAsNew
          ? FilenameGenerator.editedPdf(inputPath)
          : File(inputPath).uri.pathSegments.last;
      final outputPath =
          await _ref.read(fileServiceProvider).saveToOutput(fileName, outputBytes);

      return PdfEditorExportResult(
        outputPath: outputPath,
        fileName: fileName,
        outputSizeBytes: outputBytes.length,
        pageCount: activePages.length,
        fontWarnings: warnings.toList(),
      );
    } finally {
      sourceDocument.dispose();
      outputDocument.dispose();
    }
  }

  void _applyTextEdits(
    PdfPage page,
    PdfDocument document,
    int sourcePageIndex,
    Map<String, PdfTextEdit> textEdits,
    Set<String> warnings,
  ) {
    for (final edit in textEdits.values) {
      if (edit.metadata.pageIndex != sourcePageIndex) continue;
      if (!edit.isModified) continue;

      final bounds = edit.editBounds ?? edit.metadata.bounds;
      final graphics = page.graphics;

      if (edit.isDeleted || edit.currentText.isEmpty) {
        _eraseRegion(graphics, bounds, edit.metadata.fontSize);
        continue;
      }

      _eraseRegion(graphics, bounds, edit.metadata.fontSize);

      final resolvedFontSize = _resolveFontSize(
        edit.metadata.fontSize,
        edit.metadata.originalText,
        edit.currentText,
        edit.overflowMode,
        bounds.width,
        _fontResolver.resolve(
          document: document,
          fontName: edit.metadata.fontName,
          fontSize: edit.metadata.fontSize,
          styles: edit.metadata.fontStyle,
        ).font,
      );

      final resolution = _fontResolver.resolve(
        document: document,
        fontName: edit.metadata.fontName,
        fontSize: resolvedFontSize,
        styles: edit.metadata.fontStyle,
      );

      if (resolution.notice != null) warnings.add(resolution.notice!);

      final brush = PdfSolidBrush(
        PdfColor(
          (edit.metadata.color.r * 255).round(),
          (edit.metadata.color.g * 255).round(),
          (edit.metadata.color.b * 255).round(),
        ),
      );

      final drawBounds = Rect.fromLTWH(
        bounds.left,
        bounds.top,
        bounds.width,
        bounds.height,
      );

      graphics.drawString(
        edit.currentText,
        resolution.font,
        brush: brush,
        bounds: drawBounds,
        format: PdfStringFormat(
          alignment: _mapAlignment(edit.metadata.alignment),
          characterSpacing: edit.metadata.characterSpacing,
          lineSpacing: edit.metadata.lineSpacing,
        ),
      );
    }
  }

  void _applyNewTexts(
    PdfPage page,
    int pageIndex,
    List<PdfNewTextObject> newTexts,
  ) {
    for (final text in newTexts.where((t) => t.pageIndex == pageIndex)) {
      final font = _fontResolver.resolveForNewText(
        fontFamily: text.fontFamily,
        fontSize: text.fontSize,
        styles: text.fontStyle,
      );

      final brush = PdfSolidBrush(
        PdfColor(
          (text.color.r * 255).round(),
          (text.color.g * 255).round(),
          (text.color.b * 255).round(),
          (text.opacity * 255).round(),
        ),
      );

      page.graphics.drawString(
        text.text,
        font,
        brush: brush,
        bounds: text.bounds,
        format: PdfStringFormat(
          alignment: _mapAlignment(text.alignment),
          characterSpacing: text.letterSpacing,
        ),
      );
    }
  }

  void _applyImages(
    PdfPage page,
    int pageIndex,
    List<PdfImageObject> images,
    Set<String> deletedImageIds,
  ) {
    for (final image in images.where((img) => img.pageIndex == pageIndex)) {
      if (deletedImageIds.contains(image.id)) continue;
      final bitmap = PdfBitmap(image.imageBytes);
      page.graphics.drawImage(bitmap, image.bounds);
    }
  }

  void _applyAnnotations(
    PdfPage page,
    int pageIndex,
    List<PdfAnnotationObject> annotations,
  ) {
    for (final annotation
        in annotations.where((a) => a.pageIndex == pageIndex)) {
      final pdfColor = PdfColor(
        (annotation.color.r * 255).round(),
        (annotation.color.g * 255).round(),
        (annotation.color.b * 255).round(),
        (annotation.opacity * 255).round(),
      );

      switch (annotation.kind) {
        case AnnotationKind.highlight:
          final highlight = PdfTextMarkupAnnotation(
            annotation.bounds,
            'Highlight',
            pdfColor,
            opacity: annotation.opacity,
          );
          highlight.textMarkupAnnotationType =
              PdfTextMarkupAnnotationType.highlight;
          page.annotations.add(highlight);
        case AnnotationKind.underline:
          final underline = PdfTextMarkupAnnotation(
            annotation.bounds,
            'Underline',
            pdfColor,
            opacity: annotation.opacity,
          );
          underline.textMarkupAnnotationType =
              PdfTextMarkupAnnotationType.underline;
          page.annotations.add(underline);
        case AnnotationKind.strikethrough:
          final strike = PdfTextMarkupAnnotation(
            annotation.bounds,
            'Strike',
            pdfColor,
            opacity: annotation.opacity,
          );
          strike.textMarkupAnnotationType =
              PdfTextMarkupAnnotationType.strikethrough;
          page.annotations.add(strike);
        case AnnotationKind.rectangle:
          page.annotations.add(
            PdfRectangleAnnotation(
              annotation.bounds,
              'Rectangle',
              color: pdfColor,
            ),
          );
        case AnnotationKind.circle:
          page.annotations.add(
            PdfEllipseAnnotation(
              annotation.bounds,
              'Circle',
              color: pdfColor,
            ),
          );
        case AnnotationKind.arrow:
        case AnnotationKind.draw:
        case AnnotationKind.pen:
          if (annotation.points.length >= 2) {
            final start = annotation.points.first;
            final end = annotation.points.last;
            final line = PdfLineAnnotation(
              [
                start.dx.round(),
                start.dy.round(),
                end.dx.round(),
                end.dy.round(),
              ],
              'Draw',
              color: pdfColor,
              opacity: annotation.opacity,
              border: PdfAnnotationBorder(annotation.strokeWidth),
            );
            page.annotations.add(line);
          }
        case AnnotationKind.textBox:
        case AnnotationKind.stickyNote:
          page.annotations.add(
            PdfPopupAnnotation(
              annotation.bounds,
              annotation.text ?? 'Note',
            ),
          );
      }
    }
  }

  void _applySignatures(
    PdfPage page,
    int pageIndex,
    List<PdfSignatureObject> signatures,
  ) {
    for (final signature in signatures.where((s) => s.pageIndex == pageIndex)) {
      final bitmap = PdfBitmap(signature.imageBytes);
      page.graphics.drawImage(bitmap, signature.bounds);
    }
  }

  void _eraseRegion(PdfGraphics graphics, Rect bounds, double fontSize) {
    graphics.drawRectangle(
      brush: PdfBrushes.white,
      bounds: PdfCoordinates.eraseBounds(bounds, fontSize: fontSize),
    );
  }

  double _resolveFontSize(
    double originalSize,
    String originalText,
    String newText,
    TextOverflowMode mode,
    double maxWidth,
    PdfFont font,
  ) {
    if (mode == TextOverflowMode.keepSize || newText.length <= originalText.length) {
      return originalSize;
    }

    if (mode == TextOverflowMode.resizeText) {
      return originalSize;
    }

    final originalWidth = font.measureString(originalText).width;
    final newWidth = font.measureString(newText).width;
    if (newWidth <= maxWidth || originalWidth <= 0) return originalSize;
    return originalSize * (maxWidth / newWidth).clamp(0.5, 1.0);
  }

  PdfTextAlignment _mapAlignment(TextAlign alignment) {
    switch (alignment) {
      case TextAlign.center:
        return PdfTextAlignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return PdfTextAlignment.right;
      case TextAlign.justify:
        return PdfTextAlignment.justify;
      default:
        return PdfTextAlignment.left;
    }
  }
}
