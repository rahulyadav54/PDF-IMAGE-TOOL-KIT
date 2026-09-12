import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/editor_models.dart';
import '../utils/pdf_coordinates.dart';

/// Paints text edit previews on top of the rasterized PDF page.
class TextOverlayPainter extends CustomPainter {
  TextOverlayPainter({
    required this.textObjects,
    required this.textEdits,
    required this.newTexts,
    required this.pageIndex,
    required this.scale,
    required this.selectedTextId,
    required this.showHitAreas,
    this.previewTexts = const {},
  });

  final List<PdfTextObjectMetadata> textObjects;
  final Map<String, PdfTextEdit> textEdits;
  final List<PdfNewTextObject> newTexts;
  final int pageIndex;
  final double scale;
  final String? selectedTextId;
  final bool showHitAreas;
  final Map<String, String> previewTexts;

  @override
  void paint(Canvas canvas, Size size) {
    for (final object in textObjects) {
      final edit = textEdits[object.id];
      if (edit == null) continue;

      final display = PdfCoordinates.toDisplay(object.bounds, scale);
      final isSelected = selectedTextId == object.id;
      final preview = previewTexts[object.id];
      final isModified = edit.isModified || preview != null;
      final visibleText = preview ?? edit.currentText;

      if (edit.isDeleted) {
        _paintErase(canvas, object.bounds, object.fontSize);
        continue;
      }

      if (isModified) {
        _paintErase(canvas, object.bounds, object.fontSize);
        _paintText(
          canvas,
          display,
          visibleText,
          object.fontSize * scale,
          object.fontStyle,
          object.color,
        );
      } else if (isSelected) {
        final border = Paint()
          ..color = const Color(0xFF1769FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawRect(display, border);
        canvas.drawRect(
          display,
          Paint()..color = const Color(0xFF1769FF).withValues(alpha: 0.08),
        );
      } else if (showHitAreas) {
        final border = Paint()
          ..color = const Color(0xFF1769FF).withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
        canvas.drawRect(display, border);
      }
    }

    for (final text in newTexts.where((t) => t.pageIndex == pageIndex)) {
      final display = PdfCoordinates.toDisplay(text.bounds, scale);
      _paintText(
        canvas,
        display,
        text.text,
        text.fontSize * scale,
        text.fontStyle,
        text.color,
      );
    }
  }

  void _paintErase(Canvas canvas, Rect bounds, double fontSize) {
    final erase = PdfCoordinates.eraseBounds(bounds, fontSize: fontSize);
    final display = PdfCoordinates.toDisplay(erase, scale);
    canvas.drawRect(
      display,
      Paint()..color = Colors.white,
    );
  }

  void _paintText(
    Canvas canvas,
    Rect display,
    String text,
    double fontSize,
    List<PdfFontStyle> styles,
    Color color,
  ) {
    if (text.isEmpty) return;

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize.clamp(8, 56),
          fontWeight:
              styles.contains(PdfFontStyle.bold) ? FontWeight.bold : FontWeight.normal,
          fontStyle:
              styles.contains(PdfFontStyle.italic) ? FontStyle.italic : FontStyle.normal,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 3,
      ellipsis: '…',
    )..layout(maxWidth: display.width);

    painter.paint(canvas, Offset(display.left, display.top));
  }

  @override
  bool shouldRepaint(covariant TextOverlayPainter oldDelegate) {
    return oldDelegate.textObjects != textObjects ||
        oldDelegate.textEdits != textEdits ||
        oldDelegate.newTexts != newTexts ||
        oldDelegate.selectedTextId != selectedTextId ||
        oldDelegate.showHitAreas != showHitAreas ||
        oldDelegate.previewTexts != previewTexts ||
        oldDelegate.scale != scale;
  }

  static String? findTextAt({
    required Offset displayPoint,
    required double scale,
    required List<PdfTextObjectMetadata> objects,
    required Map<String, PdfTextEdit> edits,
  }) {
    final point = PdfCoordinates.fromDisplayPoint(displayPoint, scale);
    for (var i = objects.length - 1; i >= 0; i--) {
      final object = objects[i];
      if (edits[object.id]?.isDeleted == true) continue;
      final hit = PdfCoordinates.eraseBounds(object.bounds, fontSize: object.fontSize);
      if (hit.contains(point)) return object.id;
    }
    return null;
  }
}
