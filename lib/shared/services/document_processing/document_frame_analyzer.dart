import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Detects whether an image is already a tight document crop (e.g. native scanner).
class DocumentFrameAnalysis {
  const DocumentFrameAnalysis({
    required this.isAlreadyFramed,
    required this.maxBorderFraction,
    required this.contentFillRatio,
    required this.borderContrast,
  });

  /// True when the page already fills the frame — re-cropping would cut content.
  final bool isAlreadyFramed;

  /// Largest empty margin on any side (0–1).
  final double maxBorderFraction;

  /// How much of the image is non-uniform content (0–1).
  final double contentFillRatio;

  /// Luminance difference between border strips and center.
  final double borderContrast;

  /// Meaningful desk/background visible — safe to run auto crop.
  bool get hasSignificantBackground => maxBorderFraction >= 0.05;
}

class DocumentFrameAnalyzer {
  const DocumentFrameAnalyzer._();

  static const double _alreadyFramedMargin = 0.035;
  static const double _cropMinMargin = 0.05;

  static double get cropMinMargin => _cropMinMargin;

  static DocumentFrameAnalysis analyze(img.Image source) {
    final sample = img.copyResize(source, width: 400);
    final gray = img.grayscale(sample);
    final w = sample.width;
    final h = sample.height;

    final borderW = math.max(4, (w * 0.06).round());
    final borderH = math.max(4, (h * 0.06).round());

    double stripMean(int x0, int y0, int x1, int y1) {
      var sum = 0.0;
      var count = 0;
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          sum += gray.getPixel(x, y).r;
          count++;
        }
      }
      return count == 0 ? 0 : sum / count;
    }

    final top = stripMean(0, 0, w, borderH);
    final bottom = stripMean(0, h - borderH, w, h);
    final left = stripMean(0, 0, borderW, h);
    final right = stripMean(w - borderW, 0, w, h);
    final center = stripMean(
      (w * 0.2).round(),
      (h * 0.2).round(),
      (w * 0.8).round(),
      (h * 0.8).round(),
    );

    final borderMean = (top + bottom + left + right) / 4;
    final borderContrast = (center - borderMean).abs() / 255;

    final margins = _estimateMargins(gray);
    final maxBorder = margins.reduce(math.max);
    final contentFill = 1 - maxBorder;

    final isAlreadyFramed = maxBorder < _alreadyFramedMargin ||
        (contentFill > 0.9 && borderContrast < 0.12) ||
        (contentFill > 0.86 && maxBorder < 0.05);

    return DocumentFrameAnalysis(
      isAlreadyFramed: isAlreadyFramed,
      maxBorderFraction: maxBorder,
      contentFillRatio: contentFill,
      borderContrast: borderContrast,
    );
  }

  static List<double> _estimateMargins(img.Image gray) {
    final w = gray.width;
    final h = gray.height;

    final rowVar = List<double>.filled(h, 0);
    final colVar = List<double>.filled(w, 0);

    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        final c = gray.getPixel(x, y).r;
        final r = gray.getPixel(x + 1, y).r;
        final d = gray.getPixel(x, y + 1).r;
        final v = ((c - r).abs() + (c - d).abs()) / 255;
        rowVar[y] += v;
        colVar[x] += v;
      }
    }

    for (var i = 0; i < h; i++) {
      rowVar[i] /= w;
    }
    for (var i = 0; i < w; i++) {
      colVar[i] /= h;
    }

    final threshold = math.max(
      0.03,
      math.min(rowVar.reduce(math.max), colVar.reduce(math.max)) * 0.32,
    );

    var top = 0;
    while (top < h - 2 && rowVar[top] < threshold) top++;
    var bottom = h - 1;
    while (bottom > top + 2 && rowVar[bottom] < threshold) bottom--;
    var left = 0;
    while (left < w - 2 && colVar[left] < threshold) left++;
    var right = w - 1;
    while (right > left + 2 && colVar[right] < threshold) right--;

    return [
      top / h,
      (h - 1 - bottom) / h,
      left / w,
      (w - 1 - right) / w,
    ];
  }
}

/// How aggressively geometry should run for a capture source.
enum GeometryPolicy {
  /// Native scanner output — orientation only, never re-crop.
  preCropped,
  /// Gallery/files — crop only when background is clearly visible.
  autoDetect,
  /// User-adjusted corners — always apply perspective.
  manual,
}
