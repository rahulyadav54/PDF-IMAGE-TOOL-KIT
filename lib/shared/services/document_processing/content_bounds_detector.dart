import 'dart:math' as math;

import 'package:image/image.dart' as img;

class ContentBoundsResult {
  const ContentBoundsResult({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.shouldTrim,
    required this.confidence,
  });

  final int left;
  final int top;
  final int right;
  final int bottom;
  final bool shouldTrim;
  final double confidence;

  int get width => math.max(1, right - left);
  int get height => math.max(1, bottom - top);
}

/// Finds non-uniform content bounds to trim empty borders safely.
class ContentBoundsDetector {
  const ContentBoundsDetector._();

  static const int _sampleWidth = 360;
  static const double _activityThreshold = 0.035;
  static const double _minTrimFraction = 0.04;

  static ContentBoundsResult detect(img.Image source) {
    final sample = img.copyResize(source, width: _sampleWidth);
    final scaleX = source.width / sample.width;
    final scaleY = source.height / sample.height;
    final gray = img.grayscale(sample);

    final rowActivity = List<double>.filled(sample.height, 0);
    final colActivity = List<double>.filled(sample.width, 0);

    for (var y = 1; y < sample.height - 1; y++) {
      for (var x = 1; x < sample.width - 1; x++) {
        final center = gray.getPixel(x, y).r.toDouble();
        final right = gray.getPixel(x + 1, y).r.toDouble();
        final down = gray.getPixel(x, y + 1).r.toDouble();
        final activity = ((center - right).abs() + (center - down).abs()) / 255;
        rowActivity[y] += activity;
        colActivity[x] += activity;
      }
    }

    for (var i = 0; i < rowActivity.length; i++) {
      rowActivity[i] /= sample.width;
    }
    for (var i = 0; i < colActivity.length; i++) {
      colActivity[i] /= sample.height;
    }

    final maxRow = rowActivity.reduce(math.max);
    final maxCol = colActivity.reduce(math.max);
    final threshold = math.max(
      _activityThreshold,
      math.min(maxRow, maxCol) * 0.35,
    );

    var top = 0;
    while (top < sample.height - 2 && rowActivity[top] < threshold) {
      top++;
    }
    var bottom = sample.height - 1;
    while (bottom > top + 2 && rowActivity[bottom] < threshold) {
      bottom--;
    }
    var left = 0;
    while (left < sample.width - 2 && colActivity[left] < threshold) {
      left++;
    }
    var right = sample.width - 1;
    while (right > left + 2 && colActivity[right] < threshold) {
      right--;
    }

    final marginX = ((right - left) * 0.02).round().clamp(2, 24);
    final marginY = ((bottom - top) * 0.02).round().clamp(2, 24);
    left = math.max(0, left - marginX);
    top = math.max(0, top - marginY);
    right = math.min(sample.width - 1, right + marginX);
    bottom = math.min(sample.height - 1, bottom + marginY);

    final trimLeft = left / sample.width;
    final trimTop = top / sample.height;
    final trimRight = (sample.width - right) / sample.width;
    final trimBottom = (sample.height - bottom) / sample.height;
    final maxTrim = math.max(
      math.max(trimLeft, trimRight),
      math.max(trimTop, trimBottom),
    );

    final contentArea = (right - left) * (bottom - top);
    final imageArea = sample.width * sample.height;
    final contentRatio = contentArea / imageArea;

    final shouldTrim = maxTrim >= _minTrimFraction &&
        contentRatio > 0.2 &&
        contentRatio < 0.98;

    final confidence = shouldTrim
        ? (maxTrim * 2 + contentRatio * 0.4).clamp(0.0, 1.0)
        : 0.0;

    return ContentBoundsResult(
      left: (left * scaleX).round().clamp(0, source.width - 1),
      top: (top * scaleY).round().clamp(0, source.height - 1),
      right: (right * scaleX).round().clamp(1, source.width),
      bottom: (bottom * scaleY).round().clamp(1, source.height),
      shouldTrim: shouldTrim,
      confidence: confidence,
    );
  }

  static img.Image crop(img.Image source, ContentBoundsResult bounds) {
    if (!bounds.shouldTrim) return source;
    return img.copyCrop(
      source,
      x: bounds.left,
      y: bounds.top,
      width: bounds.width.clamp(1, source.width - bounds.left),
      height: bounds.height.clamp(1, source.height - bounds.top),
    );
  }
}
