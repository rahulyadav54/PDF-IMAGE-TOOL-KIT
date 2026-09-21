import 'dart:math' as math;

import 'package:image/image.dart' as img;

import 'document_boundary_detector.dart';

/// Chooses readable rotation AFTER perspective correction using document geometry.
class DocumentOrientationCorrector {
  const DocumentOrientationCorrector._();

  static const int _sampleWidth = 360;
  static const double _minImprovement = 0.08;

  /// Returns clockwise correction: 0, 90, 180, or 270.
  static int detectReadableRotation(
    img.Image flattened, {
    List<DocumentCorner>? sourceCorners,
  }) {
    if (flattened.width < 32 || flattened.height < 32) return 0;

    final physicalPortrait = _isPhysicallyPortrait(flattened, sourceCorners);
    final physicalLandscape = _isPhysicallyLandscape(flattened, sourceCorners);

    final sidewaysFix = _detectSidewaysTextRotation(
      flattened,
      physicalPortrait: physicalPortrait,
      physicalLandscape: physicalLandscape,
    );
    if (sidewaysFix != 0) return sidewaysFix;

    final baselineScore =
        _scoreRotation(flattened, physicalPortrait, physicalLandscape);
    var bestDegrees = 0;
    var bestScore = baselineScore;

    for (final degrees in const [90, 180, 270]) {
      final rotated = _rotate(flattened, degrees);
      final score = _scoreRotation(
        rotated,
        physicalPortrait,
        physicalLandscape,
      );

      if (score > bestScore) {
        bestScore = score;
        bestDegrees = degrees;
      }
    }

    if (bestDegrees == 0) return 0;
    if (baselineScore <= 0) return bestDegrees;

    final improvement = (bestScore - baselineScore) / baselineScore;
    return improvement >= _minImprovement ? bestDegrees : 0;
  }

  static double _scoreRotation(
    img.Image image,
    bool physicalPortrait,
    bool physicalLandscape,
  ) {
    var score = _readabilityScore(image);

    if (physicalPortrait && image.height > image.width * 1.02) {
      score *= 1.12;
    } else if (physicalLandscape && image.width > image.height * 1.02) {
      score *= 1.12;
    }

    if (physicalPortrait && image.width > image.height * 1.04) {
      score *= 0.35;
    } else if (physicalLandscape && image.height > image.width * 1.04) {
      score *= 0.35;
    } else if (!physicalPortrait &&
        !physicalLandscape &&
        image.height > image.width * 1.05) {
      score *= 1.05;
    }

    return score;
  }

  static img.Image applyRotation(img.Image source, int degrees) {
    if (degrees == 0) return source;
    return _rotate(source, degrees);
  }

  static bool _isPhysicallyPortrait(
    img.Image image,
    List<DocumentCorner>? corners,
  ) {
    if (corners != null && corners.length == 4) {
      final w = _avg(
        _dist(corners[0], corners[1]),
        _dist(corners[2], corners[3]),
      );
      final h = _avg(
        _dist(corners[0], corners[3]),
        _dist(corners[1], corners[2]),
      );
      if (h > w * 1.05) return true;
      if (w > h * 1.05) return false;
    }
    return false;
  }

  static bool _isPhysicallyLandscape(
    img.Image image,
    List<DocumentCorner>? corners,
  ) {
    if (corners != null && corners.length == 4) {
      final w = _avg(
        _dist(corners[0], corners[1]),
        _dist(corners[2], corners[3]),
      );
      final h = _avg(
        _dist(corners[0], corners[3]),
        _dist(corners[1], corners[2]),
      );
      if (w > h * 1.05) return true;
      if (h > w * 1.05) return false;
    }
    return false;
  }

  /// When width > height but stroke edges align with X, rotate to readable portrait.
  static int _detectSidewaysTextRotation(
    img.Image image, {
    required bool physicalPortrait,
    required bool physicalLandscape,
  }) {
    if (physicalLandscape) return 0;
    if (image.width <= image.height * 1.04) return 0;

    final sample = img.grayscale(img.copyResize(image, width: _sampleWidth));
    final horizontal = _gradientEnergy(sample, horizontal: true);
    final vertical = _gradientEnergy(sample, horizontal: false);
    if (horizontal <= vertical * 1.05) return 0;

    var bestDegrees = 0;
    var bestReadability = _readabilityScore(image);
    for (final degrees in const [90, 270]) {
      final rotated = _rotate(image, degrees);
      if (rotated.height <= rotated.width * 1.02 && physicalPortrait) {
        continue;
      }
      final readability = _readabilityScore(rotated);
      if (rotated.height > rotated.width &&
          readability > bestReadability * 1.06) {
        bestReadability = readability;
        bestDegrees = degrees;
      }
    }

    return bestDegrees;
  }

  static double _readabilityScore(img.Image source) {
    final sample = img.copyResize(source, width: _sampleWidth);
    final gray = img.grayscale(sample);

    final horizontal = _gradientEnergy(gray, horizontal: true);
    final vertical = _gradientEnergy(gray, horizontal: false);
    if (horizontal <= 0 && vertical <= 0) return 0;

    final dominant = math.max(horizontal, vertical);
    final weaker = math.min(horizontal, vertical);
    final lineBonus = vertical >= horizontal ? 1.15 : 0.85;
    return dominant * lineBonus + weaker * 0.2;
  }

  static double _gradientEnergy(img.Image gray, {required bool horizontal}) {
    var total = 0.0;
    if (horizontal) {
      for (var y = 0; y < gray.height; y++) {
        for (var x = 0; x < gray.width - 1; x++) {
          total += (gray.getPixel(x, y).r - gray.getPixel(x + 1, y).r).abs();
        }
      }
      return total;
    }

    for (var y = 0; y < gray.height - 1; y++) {
      for (var x = 0; x < gray.width; x++) {
        total += (gray.getPixel(x, y).r - gray.getPixel(x, y + 1).r).abs();
      }
    }
    return total;
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

  static double _dist(DocumentCorner a, DocumentCorner b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  static double _avg(double a, double b) => (a + b) / 2;
}
