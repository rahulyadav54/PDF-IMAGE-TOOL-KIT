import 'dart:ui';

/// Syncfusion text bounds and PdfGraphics both use a top-left page origin.
abstract final class PdfCoordinates {
  static Rect toDisplay(Rect bounds, double scale) {
    return Rect.fromLTWH(
      bounds.left * scale,
      bounds.top * scale,
      bounds.width * scale,
      bounds.height * scale,
    );
  }

  static Offset toDisplayPoint(Offset point, double scale) {
    return Offset(point.dx * scale, point.dy * scale);
  }

  static Offset fromDisplayPoint(Offset displayPoint, double scale) {
    return Offset(displayPoint.dx / scale, displayPoint.dy / scale);
  }

  static Rect eraseBounds(Rect bounds, {double fontSize = 12}) {
    final padX = 4.0;
    final padY = (fontSize * 0.25).clamp(3.0, 10.0);
    return Rect.fromLTWH(
      bounds.left - padX,
      bounds.top - padY,
      bounds.width + padX * 2,
      bounds.height + padY * 2,
    );
  }
}
