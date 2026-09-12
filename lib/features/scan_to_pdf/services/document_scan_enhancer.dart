import 'dart:math' as math;

import 'package:image/image.dart' as img;

import '../models/scan_enhance_kind.dart';
import 'document_image_analyzer.dart';

/// Document enhancement with adaptive analysis, CLAHE, and memory-aware sizing.
class DocumentScanEnhancer {
  const DocumentScanEnhancer._();

  static const int _illuminationMaxSide = 384;

  static img.Image enhance(
    img.Image source, {
    required ScanEnhanceMode mode,
    int maxDimension = 2200,
    bool preview = false,
  }) {
    var image = _ensureRgb(source);
    image = img.bakeOrientation(image);
    image = _resizeIfNeeded(image, preview ? 720 : maxDimension);

    switch (mode) {
      case ScanEnhanceMode.original:
        return image;
      case ScanEnhanceMode.auto:
        final analysis = DocumentImageAnalyzer.analyze(image);
        return enhance(
          image,
          mode: analysis.recommendedMode,
          maxDimension: maxDimension,
          preview: preview,
        );
      case ScanEnhanceMode.magicColor:
        return _toMagicColor(image);
      case ScanEnhanceMode.document:
        return _toColorDocument(image);
      case ScanEnhanceMode.grayscale:
        return _toGrayscaleScan(image);
      case ScanEnhanceMode.blackWhite:
        return _toBlackAndWhiteScan(image);
    }
  }

  static img.Image applyManualTweaks(
    img.Image source, {
    required double brightness,
    required double contrast,
  }) {
    if (brightness == 0 && contrast == 0) return source;

    final brightnessMultiplier = 1 + (brightness / 200);
    final contrastMultiplier = 1 + (contrast / 200);

    return img.adjustColor(
      source,
      brightness: brightnessMultiplier.clamp(0.5, 1.5),
      contrast: contrastMultiplier.clamp(0.6, 1.6),
    );
  }

  static bool isValidEnhancement(img.Image before, img.Image after) {
    final beforeEdges = DocumentImageAnalyzer.analyze(before).edgeDensity;
    final afterAnalysis = DocumentImageAnalyzer.analyze(after);
    if (afterAnalysis.meanBrightness > 0.97 || afterAnalysis.meanBrightness < 0.03) {
      return false;
    }
    if (afterAnalysis.edgeDensity < beforeEdges * 0.25) {
      return false;
    }
    return true;
  }

  static img.Image _ensureRgb(img.Image source) {
    if (source.numChannels >= 3) return img.Image.from(source);
    return source.convert(numChannels: 3);
  }

  static img.Image _resizeIfNeeded(img.Image source, int maxDimension) {
    final longest = math.max(source.width, source.height);
    if (longest <= maxDimension) return source;

    if (source.width >= source.height) {
      return img.copyResize(source, width: maxDimension);
    }
    return img.copyResize(source, height: maxDimension);
  }

  static img.Image _removeShadows(img.Image source, {double strength = 1.0}) {
    final longest = math.max(source.width, source.height);
    final scale = (_illuminationMaxSide / longest).clamp(0.1, 1.0);
    final smallW = math.max(48, (source.width * scale).round());
    final smallH = math.max(48, (source.height * scale).round());

    final small = img.copyResize(source, width: smallW, height: smallH);
    final radius = (math.min(smallW, smallH) / 12).round().clamp(2, 14);
    final backgroundSmall =
        img.gaussianBlur(img.grayscale(img.Image.from(small)), radius: radius);
    final background =
        img.copyResize(backgroundSmall, width: source.width, height: source.height);

    final output = img.Image.from(source);
    final factor = (0.9 * strength).clamp(0.5, 1.2);

    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final pixel = source.getPixel(x, y);
        final backgroundLevel = background.getPixel(x, y).r / 255.0;
        final illumination = (factor / (backgroundLevel + 0.12)).clamp(0.6, 2.4);

        final red = (pixel.r * illumination).round().clamp(0, 255);
        final green = (pixel.g * illumination).round().clamp(0, 255);
        final blue = (pixel.b * illumination).round().clamp(0, 255);
        output.setPixelRgba(x, y, red, green, blue, pixel.a);
      }
    }

    return output;
  }

  static img.Image _applyClahe(img.Image source, {double strength = 1.0}) {
    final gray = img.grayscale(source);
    final clipLimit = (2.0 * strength).clamp(1.5, 4.0);
    final lut = _buildClaheLut(gray, clipLimit);
    final output = img.Image.from(source);
    final blend = (0.55 * strength).clamp(0.35, 0.85);

    for (var y = 0; y < gray.height; y++) {
      for (var x = 0; x < gray.width; x++) {
        final l = gray.getPixel(x, y).r.toInt();
        final enhancedL = lut[l];
        final pixel = source.getPixel(x, y);
        final delta = (enhancedL - l) * blend;

        final red = (pixel.r + delta).round().clamp(0, 255);
        final green = (pixel.g + delta).round().clamp(0, 255);
        final blue = (pixel.b + delta).round().clamp(0, 255);
        output.setPixelRgba(x, y, red, green, blue, pixel.a);
      }
    }

    return output;
  }

  static List<int> _buildClaheLut(img.Image gray, double clipLimit) {
    final histogram = List<int>.filled(256, 0);
    for (final pixel in gray) {
      histogram[pixel.r.toInt()]++;
    }

    final clipThreshold = (gray.width * gray.height / 256 * clipLimit).round();
    var redistributed = 0;
    for (var i = 0; i < 256; i++) {
      if (histogram[i] > clipThreshold) {
        redistributed += histogram[i] - clipThreshold;
        histogram[i] = clipThreshold;
      }
    }
    final perBin = redistributed ~/ 256;
    for (var i = 0; i < 256; i++) {
      histogram[i] += perBin;
    }

    final cdf = List<int>.filled(256, 0);
    var sum = 0;
    for (var i = 0; i < 256; i++) {
      sum += histogram[i];
      cdf[i] = sum;
    }

    final total = gray.width * gray.height;
    return cdf.map((v) => ((v / total) * 255).round().clamp(0, 255)).toList();
  }

  static img.Image _toMagicColor(img.Image source) {
    final analysis = DocumentImageAnalyzer.analyze(source);
    var image = _removeShadows(source, strength: analysis.shadowStrength);
    image = _applyClahe(image, strength: analysis.claheStrength);
    image = img.adjustColor(
      image,
      saturation: 1.1,
      contrast: 1.08 + analysis.contrast * 0.08,
      gamma: analysis.meanBrightness < 0.45 ? 0.9 : 0.96,
    );
    image = _boostDimText(image);
    image = img.normalize(image, min: 8, max: 248);
    return _unsharpMask(image, amount: analysis.sharpenAmount);
  }

  static img.Image _toColorDocument(img.Image source) {
    final analysis = DocumentImageAnalyzer.analyze(source);
    var image = _removeShadows(source, strength: analysis.shadowStrength);
    image = _applyClahe(image, strength: analysis.claheStrength * 0.9);
    image = img.adjustColor(
      image,
      saturation: 0.86,
      contrast: 1.06 + analysis.contrast * 0.1,
      gamma: 0.97,
    );
    image = _boostDimText(image);
    image = img.normalize(image, min: 10, max: 246);
    return _unsharpMask(image, amount: analysis.sharpenAmount * 0.85);
  }

  static img.Image _toGrayscaleScan(img.Image source) {
    final analysis = DocumentImageAnalyzer.analyze(source);
    var gray = img.grayscale(_removeShadows(source, strength: analysis.shadowStrength));
    gray = _applyClahe(gray, strength: analysis.claheStrength);
    gray = img.adjustColor(gray, contrast: 1.12, gamma: 1.02);
    gray = img.normalize(gray, min: 6, max: 250);
    return _unsharpMask(gray, amount: analysis.sharpenAmount * 0.8);
  }

  static img.Image _toBlackAndWhiteScan(img.Image source) {
    final analysis = DocumentImageAnalyzer.analyze(source);
    var gray = img.grayscale(_removeShadows(source, strength: analysis.shadowStrength));
    gray = _applyClahe(gray, strength: analysis.claheStrength * 1.1);
    gray = img.adjustColor(gray, contrast: 1.18, gamma: 1.04);
    gray = img.normalize(gray, min: 0, max: 255);
    gray = _boostDimText(gray);
    return _binaryThreshold(gray, _otsuThreshold(gray));
  }

  static img.Image _boostDimText(img.Image source) {
    final blurred = img.gaussianBlur(img.Image.from(source), radius: 2);
    final output = img.Image.from(source);

    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final o = source.getPixel(x, y);
        final b = blurred.getPixel(x, y);
        final r = (o.r + (o.r - b.r) * 0.5).round().clamp(0, 255);
        final g = (o.g + (o.g - b.g) * 0.5).round().clamp(0, 255);
        final bl = (o.b + (o.b - b.b) * 0.5).round().clamp(0, 255);
        output.setPixelRgba(x, y, r, g, bl, o.a);
      }
    }

    return output;
  }

  static img.Image _unsharpMask(img.Image source, {required double amount}) {
    final blurred = img.gaussianBlur(img.Image.from(source), radius: 1);
    final output = img.Image.from(source);

    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final o = source.getPixel(x, y);
        final b = blurred.getPixel(x, y);
        final r = (o.r + (o.r - b.r) * amount).round().clamp(0, 255);
        final g = (o.g + (o.g - b.g) * amount).round().clamp(0, 255);
        final bl = (o.b + (o.b - b.b) * amount).round().clamp(0, 255);
        output.setPixelRgba(x, y, r, g, bl, o.a);
      }
    }

    return output;
  }

  static int _otsuThreshold(img.Image gray) {
    final histogram = List<int>.filled(256, 0);
    var totalPixels = 0;

    for (final pixel in gray) {
      histogram[pixel.r.toInt()]++;
      totalPixels++;
    }

    if (totalPixels == 0) return 128;

    var sum = 0;
    for (var i = 0; i < 256; i++) {
      sum += i * histogram[i];
    }

    var sumBackground = 0;
    var weightBackground = 0;
    var maxVariance = -1.0;
    var threshold = 128;

    for (var t = 0; t < 256; t++) {
      weightBackground += histogram[t];
      if (weightBackground == 0) continue;

      final weightForeground = totalPixels - weightBackground;
      if (weightForeground == 0) break;

      sumBackground += t * histogram[t];
      final meanBackground = sumBackground / weightBackground;
      final meanForeground = (sum - sumBackground) / weightForeground;
      final betweenVariance = weightBackground *
          weightForeground *
          (meanBackground - meanForeground) *
          (meanBackground - meanForeground);

      if (betweenVariance > maxVariance) {
        maxVariance = betweenVariance;
        threshold = t;
      }
    }

    return (threshold * 0.92).round().clamp(35, 215);
  }

  static img.Image _binaryThreshold(img.Image gray, int threshold) {
    final output = img.Image(width: gray.width, height: gray.height);
    for (final pixel in gray) {
      final value = pixel.r >= threshold ? 255 : 0;
      output.setPixelRgba(pixel.x, pixel.y, value, value, value, 255);
    }
    return output;
  }
}

enum ScanEnhanceMode {
  original,
  auto,
  magicColor,
  document,
  grayscale,
  blackWhite,
}

ScanEnhanceMode modeFromKind(ScanEnhanceKind kind) {
  switch (kind) {
    case ScanEnhanceKind.original:
      return ScanEnhanceMode.original;
    case ScanEnhanceKind.auto:
      return ScanEnhanceMode.auto;
    case ScanEnhanceKind.magicColor:
      return ScanEnhanceMode.magicColor;
    case ScanEnhanceKind.document:
      return ScanEnhanceMode.document;
    case ScanEnhanceKind.grayscale:
      return ScanEnhanceMode.grayscale;
    case ScanEnhanceKind.blackWhite:
      return ScanEnhanceMode.blackWhite;
  }
}
