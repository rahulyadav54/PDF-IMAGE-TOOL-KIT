import 'dart:math' as math;
import 'package:image/image.dart' as img;
import '../../../shared/services/document_processing/document_processing_logger.dart';
import '../../../shared/services/document_processing/image_quality_validator.dart';
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
        return _validateEnhancement(image, _toScanAuto(image), mode);
      case ScanEnhanceMode.magicColor:
        return _validateEnhancement(image, _toMagicColor(image), mode);
      case ScanEnhanceMode.document:
        return _validateEnhancement(image, _toColorDocument(image), mode);
      case ScanEnhanceMode.grayscale:
        return _validateEnhancement(image, _toGrayscaleScan(image), mode);
      case ScanEnhanceMode.blackWhite:
        return _validateEnhancement(image, _toBlackAndWhiteScan(image), mode);
    }
  }
  static img.Image applyManualTweaks(
    img.Image source, {
    required double brightness,
    required double contrast,
  }) {
    if (brightness == 0 && contrast == 0) return source;
    final brightnessMultiplier = (1 + (brightness / 200)).clamp(0.85, 1.25);
    final contrastMultiplier = (1 + (contrast / 200)).clamp(0.9, 1.2);
    return _safeBrightnessContrast(
      source,
      brightness: brightnessMultiplier,
      contrast: contrastMultiplier,
    );
  }
  /// Mean per-pixel luminance change between two same-sized images (0â€“1).
  static double enhancementDelta(img.Image before, img.Image after) {
    final alignedAfter = _alignForComparison(before, after);
    final sampleW = math.min(before.width, 160);
    final sampleH = math.min(before.height, 160);
    final beforeSample = img.copyResize(before, width: sampleW, height: sampleH);
    final afterSample =
        img.copyResize(alignedAfter, width: sampleW, height: sampleH);
    var delta = 0.0;
    var count = 0;
    for (var y = 0; y < beforeSample.height; y++) {
      for (var x = 0; x < beforeSample.width; x++) {
        final b = beforeSample.getPixel(x, y);
        final a = afterSample.getPixel(x, y);
        delta += ((b.r - a.r).abs() + (b.g - a.g).abs() + (b.b - a.b).abs()) /
            (3 * 255);
        count++;
      }
    }
    return count == 0 ? 0 : delta / count;
  }
  /// True when enhancement destroyed readable content (white wash OR black crush).
  static bool isWashedOut(img.Image image) {
    final analysis = DocumentImageAnalyzer.analyze(image);

    // Near-black Crush — must check BEFORE dark-ink short-circuit.
    if (analysis.meanBrightness < 0.12) return true;
    if (_blackPixelRatio(image) > 0.70) return true;

    if (_hasDarkInk(image)) {
      // Still reject if paper is crushed black while somehow having dark pixels.
      if (analysis.meanBrightness < 0.22 && _blackPixelRatio(image) > 0.55) {
        return true;
      }
      return false;
    }

    if (analysis.meanBrightness < 0.02) return true;

    if (_hasForegroundContent(image)) {
      return _whitePixelRatio(image) > 0.99 &&
          analysis.meanBrightness > 0.995 &&
          analysis.contrast < 0.006;
    }

    if (_whitePixelRatio(image) > 0.96) return true;
    if (analysis.meanBrightness > 0.993 && analysis.contrast < 0.008) {
      return true;
    }
    return false;
  }

  static double _blackPixelRatio(img.Image image) {
    final sample = img.copyResize(image, width: 120);
    var black = 0;
    var count = 0;
    for (final pixel in sample) {
      final luma = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114;
      if (luma < 40) black++;
      count++;
    }
    return count == 0 ? 0 : black / count;
  }

  static bool _hasDarkInk(img.Image image) {
    final sample = img.copyResize(image, width: 160);
    var minChannel = 255;
    for (final pixel in sample) {
      minChannel = math.min(minChannel, pixel.r.toInt());
      minChannel = math.min(minChannel, pixel.g.toInt());
      minChannel = math.min(minChannel, pixel.b.toInt());
    }
    return minChannel < 130;
  }

  static bool enhancementWasApplied(
    img.Image before,
    img.Image after, {
    required ScanEnhanceMode mode,
  }) {
    if (mode == ScanEnhanceMode.original) return false;
    if (isWashedOut(after)) return false;
    final beforeOriented = img.bakeOrientation(img.Image.from(before));
    final delta = enhancementDelta(beforeOriented, after);
    if (delta < 0.001) return false;
    final afterAnalysis = DocumentImageAnalyzer.analyze(after);
    if (afterAnalysis.meanBrightness < 0.02) {
      return false;
    }
    if (mode == ScanEnhanceMode.blackWhite ||
        mode == ScanEnhanceMode.grayscale) {
      if (_whitePixelRatio(after) > 0.95 && !_hasForegroundContent(after)) {
        return false;
      }
      return true;
    }

    if (_whitePixelRatio(after) > 0.96 && !_hasForegroundContent(after)) {
      return false;
    }
    if (afterAnalysis.meanBrightness > 0.985 &&
        afterAnalysis.contrast < 0.015) {
      return false;
    }

    final beforeAnalysis = DocumentImageAnalyzer.analyze(beforeOriented);
    if (!_hasForegroundContent(after) &&
        afterAnalysis.edgeDensity < beforeAnalysis.edgeDensity * 0.05) {
      return false;
    }

    return true;
  }
  static bool _hasForegroundContent(img.Image image) {
    final sample = img.copyResize(image, width: 160);
    var darkPixels = 0;
    for (final pixel in sample) {
      if (pixel.r < 185) darkPixels++;
    }
    return darkPixels > 2;
  }

  static double _whitePixelRatio(img.Image image) {
    final sample = img.copyResize(image, width: 120);
    var white = 0;
    var count = 0;
    for (final pixel in sample) {
      if (pixel.r > 242 && pixel.g > 242 && pixel.b > 242) white++;
      count++;
    }
    return count == 0 ? 0 : white / count;
  }
  static img.Image _alignForComparison(img.Image reference, img.Image candidate) {
    if (reference.width == candidate.width &&
        reference.height == candidate.height) {
      return candidate;
    }
    return img.copyResize(
      candidate,
      width: reference.width,
      height: reference.height,
    );
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
    return _safeIlluminationFlatten(source, strength: strength);
  }

  /// Caps per-pixel gain to prevent white-patch blowout on handwriting.
  static img.Image _safeIlluminationFlatten(
    img.Image source, {
    double strength = 1.0,
  }) {
    final analysis = DocumentImageAnalyzer.analyze(source);
    if (analysis.shadowIntensity < 0.22 && analysis.meanBrightness > 0.42) {
      return img.Image.from(source);
    }

    var strengthScale = strength.clamp(0.15, 0.55);
    if (analysis.meanBrightness > 0.68) strengthScale *= 0.45;
    if (analysis.contentType == DocumentContentType.handwritten) {
      strengthScale *= 0.55;
    }

    final longest = math.max(source.width, source.height);
    final scale = (_illuminationMaxSide / longest).clamp(0.1, 1.0);
    final smallW = math.max(48, (source.width * scale).round());
    final smallH = math.max(48, (source.height * scale).round());
    final small = img.copyResize(source, width: smallW, height: smallH);
    final radius = (math.min(smallW, smallH) / 14).round().clamp(3, 12);
    final backgroundSmall =
        img.gaussianBlur(img.grayscale(img.Image.from(small)), radius: radius);
    final background =
        img.copyResize(backgroundSmall, width: source.width, height: source.height);
    final output = img.Image.from(source);

    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final pixel = source.getPixel(x, y);
        final luma = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114;
        if (luma < 120) {
          output.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, pixel.a);
          continue;
        }

        final backgroundLevel = background.getPixel(x, y).r / 255.0;
        final target = 0.72 + strengthScale * 0.18;
        final illumination =
            (1 + (target - backgroundLevel) * strengthScale).clamp(0.92, 1.12);
        final red = (pixel.r * illumination).round().clamp(0, 252);
        final green = (pixel.g * illumination).round().clamp(0, 252);
        final blue = (pixel.b * illumination).round().clamp(0, 252);
        output.setPixelRgba(x, y, red, green, blue, pixel.a);
      }
    }
    return output;
  }
  static img.Image _applyClahe(img.Image source, {double strength = 1.0}) {
    final gray = img.grayscale(source);
    final clipLimit = (1.6 * strength).clamp(1.2, 2.8);
    final lut = _buildClaheLut(gray, clipLimit);
    final output = img.Image.from(source);
    final blend = (0.42 * strength).clamp(0.2, 0.5);
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
  /// Safe automatic scan — visible improvement without threshold/invert/black crush.
  static img.Image _toScanAuto(img.Image source) {
    DocumentProcessingLogger.logStageStats(stage: 'AUTO_INPUT', image: source);
    final image = _runSafeDocumentPipeline(source, mode: ScanEnhanceMode.auto);
    DocumentProcessingLogger.logStageStats(stage: 'AUTO_OUTPUT', image: image);
    return image;
  }

  /// Shared safe pipeline for Auto / Color / Document / Gray (no B&W threshold).
  static img.Image _runSafeDocumentPipeline(
    img.Image source, {
    required ScanEnhanceMode mode,
  }) {
    final analysis = DocumentImageAnalyzer.analyze(source);
    var image = img.Image.from(source);

    if (analysis.shadowIntensity > 0.22 || analysis.meanBrightness < 0.52) {
      image = _safeIlluminationFlatten(image, strength: 0.34);
    }

    image = _gentlePaperLift(image);

    var brightness = 1.06;
    var contrast = 1.10;
    if (analysis.meanBrightness < 0.42) {
      brightness = 1.10;
      contrast = 1.12;
    } else if (analysis.meanBrightness > 0.68) {
      brightness = 1.04;
      contrast = 1.07;
    }

    image = _safeBrightnessContrast(
      image,
      brightness: brightness,
      contrast: contrast,
    );

    if (analysis.contrast < 0.30 && analysis.meanBrightness < 0.65) {
      image = _applyClahe(image, strength: 0.40);
    }

    if (mode == ScanEnhanceMode.magicColor) {
      image = _mildSaturationBoost(image, 1.08);
    }

    final sharpen = mode == ScanEnhanceMode.magicColor ? 0.22 : 0.17;
    image = _unsharpMask(image, amount: sharpen);

    return image;
  }

  /// Lifts paper toward white without blowing highlights or touching ink.
  static img.Image _gentlePaperLift(img.Image source) {
    final output = img.Image.from(source);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final p = source.getPixel(x, y);
        final luma = p.r * 0.299 + p.g * 0.587 + p.b * 0.114;
        if (luma < 150 || luma > 248) {
          output.setPixelRgba(x, y, p.r, p.g, p.b, p.a);
          continue;
        }
        final lift = ((luma - 150) / 90).clamp(0.0, 1.0);
        final amount = (0.18 * (1 - lift) + 0.06).clamp(0.04, 0.18);
        final r = (p.r + (255 - p.r) * amount).round().clamp(0, 252);
        final g = (p.g + (255 - p.g) * amount).round().clamp(0, 252);
        final b = (p.b + (255 - p.b) * amount).round().clamp(0, 252);
        output.setPixelRgba(x, y, r, g, b, p.a);
      }
    }
    return output;
  }

  /// Saturation boost without img.adjustColor (which can zero the image).
  static img.Image _mildSaturationBoost(img.Image source, double factor) {
    final f = factor.clamp(1.0, 1.15);
    final output = img.Image.from(source);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final p = source.getPixel(x, y);
        final luma = p.r * 0.299 + p.g * 0.587 + p.b * 0.114;
        if (luma < 95) {
          output.setPixelRgba(x, y, p.r, p.g, p.b, p.a);
          continue;
        }
        final r = (luma + (p.r - luma) * f).round().clamp(0, 255);
        final g = (luma + (p.g - luma) * f).round().clamp(0, 255);
        final b = (luma + (p.b - luma) * f).round().clamp(0, 255);
        output.setPixelRgba(x, y, r, g, b, p.a);
      }
    }
    return output;
  }

  /// Manual brightness/contrast that cannot crush the image to black.
  /// brightness: 1.0 = unchanged, >1 brighter; contrast: 1.0 = unchanged.
  static img.Image _safeBrightnessContrast(
    img.Image source, {
    required double brightness,
    required double contrast,
  }) {
    final b = brightness.clamp(0.85, 1.25);
    final c = contrast.clamp(0.9, 1.2);
    if ((b - 1.0).abs() < 0.001 && (c - 1.0).abs() < 0.001) {
      return img.Image.from(source);
    }

    final output = img.Image.from(source);
    const mid = 128.0;
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final p = source.getPixel(x, y);
        int map(num channel) {
          final centered = (channel - mid) * c + mid;
          return (centered * b).round().clamp(0, 255);
        }

        output.setPixelRgba(x, y, map(p.r), map(p.g), map(p.b), p.a);
      }
    }
    return output;
  }

  static img.Image _validateEnhancement(
    img.Image source,
    img.Image processed,
    ScanEnhanceMode mode,
  ) {
    final valid = ImageQualityValidator.isValidDimensions(processed);
    final washedOut = isWashedOut(processed);
    final blackened = ImageQualityValidator.isRadicallyDarkened(source, processed);
    final inverted = ImageQualityValidator.isPolarityInverted(source, processed);
    final hasArtifacts = mode == ScanEnhanceMode.blackWhite ||
            mode == ScanEnhanceMode.grayscale
        ? false
        : ImageQualityValidator.hasProcessingArtifacts(source, processed);

    final applied =
        valid && !washedOut && !blackened && !inverted && !hasArtifacts;

    DocumentProcessingLogger.logEnhancement(
      mode: mode.name,
      inputWidth: source.width,
      inputHeight: source.height,
      outputWidth: processed.width,
      outputHeight: processed.height,
      applied: applied,
      artifactDetected: !applied,
    );
    DocumentProcessingLogger.logStageStats(stage: 'VALIDATE_SOURCE', image: source);
    DocumentProcessingLogger.logStageStats(
      stage: applied ? 'VALIDATE_ACCEPTED' : 'VALIDATE_REJECTED',
      image: processed,
    );

    if (!applied) {
      // Never show a corrupted/blackened result.
      return img.Image.from(source);
    }
    return processed;
  }

  static img.Image _mildDenoise(img.Image source) {
    return img.gaussianBlur(img.Image.from(source), radius: 1);
  }

  static img.Image _preserveInkFromSource(img.Image original, img.Image enhanced) {
    var reference = original;
    if (reference.width != enhanced.width || reference.height != enhanced.height) {
      reference = img.copyResize(
        reference,
        width: enhanced.width,
        height: enhanced.height,
      );
    }

    final output = img.Image.from(enhanced);
    for (var y = 0; y < enhanced.height; y++) {
      for (var x = 0; x < enhanced.width; x++) {
        final o = reference.getPixel(x, y);
        final luma = o.r * 0.299 + o.g * 0.587 + o.b * 0.114;
        if (luma >= 120) continue;

        final e = enhanced.getPixel(x, y);
        final blend = (1 - luma / 120).clamp(0.45, 0.85);
        final r = (e.r * (1 - blend) + o.r * blend).round().clamp(0, 255);
        final g = (e.g * (1 - blend) + o.g * blend).round().clamp(0, 255);
        final b = (e.b * (1 - blend) + o.b * blend).round().clamp(0, 255);
        output.setPixelRgba(x, y, r, g, b, e.a);
      }
    }
    return output;
  }

  static img.Image _grayWorldWhiteBalance(img.Image source) {
    var rSum = 0.0;
    var gSum = 0.0;
    var bSum = 0.0;
    var count = 0;
    final sample = img.copyResize(source, width: 160);
    for (final pixel in sample) {
      rSum += pixel.r;
      gSum += pixel.g;
      bSum += pixel.b;
      count++;
    }
    if (count == 0) return img.Image.from(source);

    final avg = (rSum + gSum + bSum) / (3 * count);
    if (avg < 1) return img.Image.from(source);

    final rGain = avg / (rSum / count);
    final gGain = avg / (gSum / count);
    final bGain = avg / (bSum / count);
    final output = img.Image.from(source);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final p = source.getPixel(x, y);
        final r = (p.r * rGain).round().clamp(0, 255);
        final g = (p.g * gGain).round().clamp(0, 255);
        final b = (p.b * bGain).round().clamp(0, 255);
        output.setPixelRgba(x, y, r, g, b, p.a);
      }
    }
    return output;
  }

  static img.Image _whitenPaperBackground(img.Image source) {
    final output = img.Image.from(source);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final p = source.getPixel(x, y);
        final luma = (p.r * 0.299 + p.g * 0.587 + p.b * 0.114);
        if (luma > 215) {
          final lift = ((luma - 215) / 40).clamp(0.0, 1.0);
          final r = (p.r + (255 - p.r) * lift * 0.4).round().clamp(0, 255);
          final g = (p.g + (255 - p.g) * lift * 0.4).round().clamp(0, 255);
          final b = (p.b + (255 - p.b) * lift * 0.4).round().clamp(0, 255);
          output.setPixelRgba(x, y, r, g, b, p.a);
        }
      }
    }
    return output;
  }

  static img.Image _toMagicColor(img.Image source) {
    return _runSafeDocumentPipeline(source, mode: ScanEnhanceMode.magicColor);
  }

  static img.Image _toColorDocument(img.Image source) {
    return _runSafeDocumentPipeline(source, mode: ScanEnhanceMode.document);
  }
  static img.Image _normalizeForDocument(img.Image image, double meanBrightness) {
    if (meanBrightness > 0.78) {
      return _safeBrightnessContrast(image, brightness: 1.02, contrast: 1.05);
    }
    if (meanBrightness < 0.42) {
      return _safeBrightnessContrast(image, brightness: 1.08, contrast: 1.06);
    }
    return _safeBrightnessContrast(image, brightness: 1.03, contrast: 1.05);
  }

  static img.Image _toGrayscaleScan(img.Image source) {
    final enhanced =
        _runSafeDocumentPipeline(source, mode: ScanEnhanceMode.grayscale);
    return img.grayscale(enhanced);
  }
  static img.Image _applyAdaptiveSharpen(
    img.Image source,
    DocumentImageAnalysis analysis, {
    double amountScale = 1.0,
  }) {
    var image = _unsharpMask(
      source,
      amount: analysis.sharpenAmount * amountScale,
    );
    if (analysis.sharpness < 0.22) {
      image = _unsharpMask(
        image,
        amount: analysis.sharpenAmount * amountScale * 0.35,
      );
    }
    return image;
  }
  static img.Image _toBlackAndWhiteScan(img.Image source) {
    // Threshold only in explicit B&W mode — never in Auto/Color/Gray.
    var gray = img.grayscale(img.Image.from(source));
    gray = _safeBrightnessContrast(gray, brightness: 1.03, contrast: 1.08);
    return _adaptiveBinaryThreshold(gray);
  }
  static img.Image _adaptiveBinaryThreshold(img.Image gray) {
    final w = gray.width;
    final h = gray.height;
    final block = (math.min(w, h) / 16).round().clamp(21, 45);
    final half = block ~/ 2;
    final integral = List.generate(h + 1, (_) => List<double>.filled(w + 1, 0));
    final integralSq = List.generate(h + 1, (_) => List<double>.filled(w + 1, 0));
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final v = gray.getPixel(x, y).r.toDouble();
        integral[y + 1][x + 1] =
            v + integral[y][x + 1] + integral[y + 1][x] - integral[y][x];
        integralSq[y + 1][x + 1] = v * v +
            integralSq[y][x + 1] +
            integralSq[y + 1][x] -
            integralSq[y][x];
      }
    }
    double rectSum(List<List<double>> table, int x1, int y1, int x2, int y2) {
      return table[y2 + 1][x2 + 1] -
          table[y1][x2 + 1] -
          table[y2 + 1][x1] +
          table[y1][x1];
    }
    final globalT = _otsuThreshold(gray);
    const k = 0.12;
    const range = 128.0;
    final output = img.Image(width: w, height: h);
    for (var y = 0; y < h; y++) {
      final y1 = math.max(0, y - half);
      final y2 = math.min(h - 1, y + half);
      for (var x = 0; x < w; x++) {
        final x1 = math.max(0, x - half);
        final x2 = math.min(w - 1, x + half);
        final area = (x2 - x1 + 1) * (y2 - y1 + 1);
        final sum = rectSum(integral, x1, y1, x2, y2);
        final sumSq = rectSum(integralSq, x1, y1, x2, y2);
        final mean = sum / area;
        final variance = (sumSq / area) - (mean * mean);
        final std = math.sqrt(variance.clamp(0, 65025));
        final localT = mean * (1 + k * (std / range - 1));
        final threshold = (localT * 0.72 + globalT * 0.28).clamp(35.0, 210.0);
        final value = gray.getPixel(x, y).r >= threshold ? 255 : 0;
        output.setPixelRgba(x, y, value, value, value, 255);
      }
    }
    return output;
  }
  static img.Image _boostDimText(img.Image source, {double strength = 0.35}) {
    final blurred = img.gaussianBlur(img.Image.from(source), radius: 2);
    final output = img.Image.from(source);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final o = source.getPixel(x, y);
        final b = blurred.getPixel(x, y);
        final r = (o.r + (o.r - b.r) * strength).round().clamp(0, 255);
        final g = (o.g + (o.g - b.g) * strength).round().clamp(0, 255);
        final bl = (o.b + (o.b - b.b) * strength).round().clamp(0, 255);
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
        final luma = o.r * 0.299 + o.g * 0.587 + o.b * 0.114;
        final inkGuard = luma < 130 ? 0.12 : (luma < 180 ? 0.45 : 1.0);
        final effective = amount * inkGuard;
        final r = (o.r + (o.r - b.r) * effective).round().clamp(0, 255);
        final g = (o.g + (o.g - b.g) * effective).round().clamp(0, 255);
        final bl = (o.b + (o.b - b.b) * effective).round().clamp(0, 255);
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
    return (threshold * 0.95).round().clamp(45, 200);
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
