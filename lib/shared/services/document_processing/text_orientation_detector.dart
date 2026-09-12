import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Detects text/document rotation using horizontal projection variance.
class TextOrientationDetector {
  const TextOrientationDetector._();

  static const int _sampleWidth = 320;
  static const double _minImprovement = 0.18;

  /// Returns clockwise correction degrees: 0, 90, 180, or 270.
  static int detectCorrectionDegrees(
    img.Image source, {
    required bool documentLike,
  }) {
    if (!documentLike) return 0;

    final rotations = <int, double>{};
    for (final degrees in const [0, 90, 180, 270]) {
      final rotated = _rotate(source, degrees);
      final sample = img.copyResize(rotated, width: _sampleWidth);
      rotations[degrees] = _horizontalProjectionScore(img.grayscale(sample));
    }

    final baseline = rotations[0] ?? 0;
    var bestDegrees = 0;
    var bestScore = baseline;

    for (final entry in rotations.entries) {
      if (entry.value > bestScore) {
        bestScore = entry.value;
        bestDegrees = entry.key;
      }
    }

    if (bestDegrees == 0) return 0;
    if (baseline <= 0) return bestDegrees;

    final improvement = (bestScore - baseline) / baseline;
    return improvement >= _minImprovement ? bestDegrees : 0;
  }

  static img.Image applyRotation(img.Image source, int degrees) {
    if (degrees == 0) return source;
    return _rotate(source, degrees);
  }

  static img.Image _rotate(img.Image source, int degrees) {
    switch (degrees) {
      case 90:
        return img.copyRotate(source, angle: 90);
      case 180:
        return img.copyRotate(source, angle: 180);
      case 270:
        return img.copyRotate(source, angle: 270);
      default:
        return source;
    }
  }

  static double _horizontalProjectionScore(img.Image gray) {
    if (gray.width == 0 || gray.height == 0) return 0;

    var totalVariance = 0.0;
    for (var y = 0; y < gray.height; y++) {
      var sum = 0.0;
      var sumSq = 0.0;
      for (var x = 0; x < gray.width; x++) {
        final value = gray.getPixel(x, y).r.toDouble();
        sum += value;
        sumSq += value * value;
      }
      final mean = sum / gray.width;
      final variance = (sumSq / gray.width) - (mean * mean);
      totalVariance += math.max(0, variance);
    }

    return totalVariance / gray.height;
  }
}
