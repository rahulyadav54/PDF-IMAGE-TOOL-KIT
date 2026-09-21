import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Validates processed images before display to catch black/white artifacts.
class ImageQualityValidator {
  const ImageQualityValidator._();

  static bool isValidDimensions(img.Image image) {
    return image.width > 0 && image.height > 0;
  }

  /// Stage statistics for debugging the scan pipeline.
  static ImageStageStats computeStats(img.Image image) {
    final sample = img.copyResize(
      image,
      width: math.min(image.width, 160),
      height: math.min(image.height, 200),
    );
    var minV = 255.0;
    var maxV = 0.0;
    var sum = 0.0;
    var black = 0;
    var white = 0;
    var count = 0;

    for (final pixel in sample) {
      final luma = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114;
      minV = math.min(minV, luma);
      maxV = math.max(maxV, luma);
      sum += luma;
      if (luma < 40) black++;
      if (luma > 245) white++;
      count++;
    }

    final n = math.max(1, count);
    return ImageStageStats(
      width: image.width,
      height: image.height,
      channels: image.numChannels,
      min: minV,
      max: maxV,
      mean: sum / n,
      blackPixelPercentage: black / n,
      whitePixelPercentage: white / n,
    );
  }

  /// Detects large blown-out regions introduced by bad enhancement/transform.
  static bool hasProcessingArtifacts(img.Image before, img.Image after) {
    if (!isValidDimensions(after)) return true;
    if (isRadicallyDarkened(before, after)) return true;
    if (isPolarityInverted(before, after)) return true;

    final sampleW = math.min(math.min(before.width, after.width), 200);
    final sampleH = math.min(math.min(before.height, after.height), 260);
    final bSample = img.copyResize(before, width: sampleW, height: sampleH);
    final aSample = img.copyResize(after, width: sampleW, height: sampleH);

    var blownHighlights = 0;
    var lostInk = 0;
    var crushedPaper = 0;
    var count = 0;

    for (var y = 0; y < sampleH; y++) {
      for (var x = 0; x < sampleW; x++) {
        final b = bSample.getPixel(x, y);
        final a = aSample.getPixel(x, y);
        final bLuma = _luma(b);
        final aLuma = _luma(a);

        if (aLuma > 246 && aLuma > bLuma + 90) blownHighlights++;
        if (bLuma < 95 && aLuma > bLuma + 120) lostInk++;
        // Light paper crushed to near-black.
        if (bLuma > 140 && aLuma < 45) crushedPaper++;
        count++;
      }
    }

    if (count == 0) return false;

    final blownRatio = blownHighlights / count;
    final inkLossRatio = lostInk / count;
    final crushRatio = crushedPaper / count;
    return blownRatio > 0.08 || inkLossRatio > 0.12 || crushRatio > 0.12;
  }

  /// Light/normal document that became suspiciously dark after processing.
  static bool isRadicallyDarkened(img.Image before, img.Image after) {
    final b = computeStats(before);
    final a = computeStats(after);

    if (a.mean < 30 && b.mean > 90) return true;
    if (a.blackPixelPercentage > 0.70 && b.blackPixelPercentage < 0.35) {
      return true;
    }
    if (b.mean > 100 && a.mean < b.mean * 0.45) return true;
    if (a.mean < 45 && b.mean > 110) return true;
    return false;
  }

  /// Detects accidental negative / inverted polarity vs source.
  static bool isPolarityInverted(img.Image before, img.Image after) {
    final b = computeStats(before);
    final a = computeStats(after);
    // Source was light paper; result is dark with few whites.
    if (b.mean > 120 &&
        a.mean < 80 &&
        a.whitePixelPercentage < 0.05 &&
        b.whitePixelPercentage + (b.mean > 140 ? 0.1 : 0) > 0.02) {
      return true;
    }
    // Mean crossed from bright to dark while blacks exploded.
    if (b.mean > 140 &&
        a.mean < 100 &&
        a.blackPixelPercentage > b.blackPixelPercentage + 0.4) {
      return true;
    }
    return false;
  }

  static bool isMostlyBlank(img.Image image) {
    final sample = img.copyResize(image, width: 120);
    var white = 0;
    for (final pixel in sample) {
      if (pixel.r > 248 && pixel.g > 248 && pixel.b > 248) white++;
    }
    return white / sample.width / sample.height > 0.97;
  }

  static double _luma(img.Pixel p) => p.r * 0.299 + p.g * 0.587 + p.b * 0.114;
}

class ImageStageStats {
  const ImageStageStats({
    required this.width,
    required this.height,
    required this.channels,
    required this.min,
    required this.max,
    required this.mean,
    required this.blackPixelPercentage,
    required this.whitePixelPercentage,
  });

  final int width;
  final int height;
  final int channels;
  final double min;
  final double max;
  final double mean;
  final double blackPixelPercentage;
  final double whitePixelPercentage;
}
