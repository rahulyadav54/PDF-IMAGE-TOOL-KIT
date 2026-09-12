import 'package:flutter/material.dart';

import '../models/editor_models.dart';
import '../utils/pdf_coordinates.dart';

class AnnotationPainter extends CustomPainter {
  AnnotationPainter({
    required this.annotations,
    required this.scale,
    required this.currentStroke,
  });

  final List<PdfAnnotationObject> annotations;
  final double scale;
  final List<Offset> currentStroke;

  @override
  void paint(Canvas canvas, Size size) {
    for (final annotation in annotations) {
      final bounds = PdfCoordinates.toDisplay(annotation.bounds, scale);

      final paint = Paint()
        ..color = annotation.color.withValues(alpha: annotation.opacity)
        ..strokeWidth = annotation.strokeWidth
        ..style = PaintingStyle.stroke;

      switch (annotation.kind) {
        case AnnotationKind.highlight:
          canvas.drawRect(
            bounds,
            Paint()
              ..color = annotation.color.withValues(alpha: 0.28)
              ..style = PaintingStyle.fill,
          );
        case AnnotationKind.rectangle:
          canvas.drawRect(bounds, paint);
        case AnnotationKind.circle:
          canvas.drawOval(bounds, paint);
        case AnnotationKind.underline:
          canvas.drawLine(bounds.bottomLeft, bounds.bottomRight, paint);
        case AnnotationKind.strikethrough:
          canvas.drawLine(bounds.centerLeft, bounds.centerRight, paint);
        case AnnotationKind.draw:
        case AnnotationKind.pen:
        case AnnotationKind.arrow:
          if (annotation.points.length >= 2) {
            final path = Path();
            final first =
                PdfCoordinates.toDisplayPoint(annotation.points.first, scale);
            path.moveTo(first.dx, first.dy);
            for (var i = 1; i < annotation.points.length; i++) {
              final point =
                  PdfCoordinates.toDisplayPoint(annotation.points[i], scale);
              path.lineTo(point.dx, point.dy);
            }
            canvas.drawPath(path, paint);
          }
        case AnnotationKind.textBox:
        case AnnotationKind.stickyNote:
          canvas.drawRect(
            bounds,
            Paint()
              ..color = const Color(0xFFFFF59D).withValues(alpha: 0.85)
              ..style = PaintingStyle.fill,
          );
      }
    }

    if (currentStroke.length >= 2) {
      final strokePaint = Paint()
        ..color = const Color(0xFF1769FF)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path()..moveTo(currentStroke.first.dx, currentStroke.first.dy);
      for (var i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) {
    return oldDelegate.annotations != annotations ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.scale != scale;
  }
}
