import 'dart:math' as math;

import 'package:image/image.dart' as img;

import 'document_scan_enhancer.dart';

enum DocumentContentType {
  textDocument,
  receipt,
  photo,
  idCard,
  certificate,
  handwritten,
  mixed,
}

class DocumentImageAnalysis {
  const DocumentImageAnalysis({
    required this.contentType,
    required this.meanBrightness,
    required this.contrast,
    required this.noiseLevel,
    required this.shadowIntensity,
    required this.edgeDensity,
    required this.recommendedMode,
    required this.claheStrength,
    required this.shadowStrength,
    required this.sharpenAmount,
  });

  final DocumentContentType contentType;
  final double meanBrightness;
  final double contrast;
  final double noiseLevel;
  final double shadowIntensity;
  final double edgeDensity;
  final ScanEnhanceMode recommendedMode;
  final double claheStrength;
  final double shadowStrength;
  final double sharpenAmount;
}

/// Analyzes document images to choose adaptive enhancement parameters.
class DocumentImageAnalyzer {
  const DocumentImageAnalyzer._();

  static DocumentImageAnalysis analyze(img.Image source) {
    final sample = img.copyResize(source, width: 160);
    final gray = img.grayscale(sample);
    final stats = _computeStats(gray);
    final edgeDensity = _edgeDensity(gray);
    final contentType = _detectContentType(sample, stats, edgeDensity);
    final recommendedMode = _recommendedMode(contentType, stats, edgeDensity);
    final shadowIntensity = _shadowIntensity(sample);

    return DocumentImageAnalysis(
      contentType: contentType,
      meanBrightness: stats.mean,
      contrast: stats.contrast,
      noiseLevel: stats.noise,
      shadowIntensity: shadowIntensity,
      edgeDensity: edgeDensity,
      recommendedMode: recommendedMode,
      claheStrength: _claheStrength(stats, edgeDensity),
      shadowStrength: shadowIntensity.clamp(0.4, 1.0),
      sharpenAmount: _sharpenAmount(stats, edgeDensity),
    );
  }

  static _Stats _computeStats(img.Image gray) {
    var sum = 0.0;
    var sumSq = 0.0;
    var count = 0;
    var noise = 0.0;

    for (var y = 1; y < gray.height - 1; y++) {
      for (var x = 1; x < gray.width - 1; x++) {
        final center = gray.getPixel(x, y).r;
        final right = gray.getPixel(x + 1, y).r;
        final down = gray.getPixel(x, y + 1).r;
        sum += center;
        sumSq += center * center;
        noise += (center - right).abs() + (center - down).abs();
        count++;
      }
    }

    final mean = count == 0 ? 128.0 : sum / count;
    final variance = count == 0 ? 0.0 : (sumSq / count) - (mean * mean);
    final contrast = math.sqrt(variance.clamp(0, 65025)) / 128;

    return _Stats(
      mean: mean / 255,
      contrast: contrast.clamp(0, 1),
      noise: (noise / (count * 2 * 255)).clamp(0, 1),
    );
  }

  static double _edgeDensity(img.Image gray) {
    var edgeCount = 0;
    var total = 0;

    for (var y = 1; y < gray.height - 1; y++) {
      for (var x = 1; x < gray.width - 1; x++) {
        final center = gray.getPixel(x, y).r;
        final right = gray.getPixel(x + 1, y).r;
        final down = gray.getPixel(x, y + 1).r;
        if ((center - right).abs() > 24 || (center - down).abs() > 24) {
          edgeCount++;
        }
        total++;
      }
    }

    return total == 0 ? 0 : edgeCount / total;
  }

  static double _shadowIntensity(img.Image sample) {
    final small = img.copyResize(sample, width: 48);
    final gray = img.grayscale(small);
    var minL = 255.0;
    var maxL = 0.0;

    for (final pixel in gray) {
      final l = pixel.r.toDouble();
      minL = math.min(minL, l);
      maxL = math.max(maxL, l);
    }

    return ((maxL - minL) / 255).clamp(0, 1);
  }

  static DocumentContentType _detectContentType(
    img.Image sample,
    _Stats stats,
    double edgeDensity,
  ) {
    if (edgeDensity > 0.14 && stats.contrast > 0.35) {
      return DocumentContentType.receipt;
    }
    if (edgeDensity > 0.1 && stats.mean < 0.55) {
      return DocumentContentType.textDocument;
    }
    if (stats.contrast < 0.2 && stats.mean > 0.65) {
      return DocumentContentType.photo;
    }
    if (sample.width / sample.height > 1.35 || sample.height / sample.width > 1.35) {
      if (edgeDensity > 0.08) return DocumentContentType.idCard;
    }
    if (stats.contrast > 0.28 && stats.mean > 0.5) {
      return DocumentContentType.certificate;
    }
    if (edgeDensity > 0.06 && stats.noise > 0.12) {
      return DocumentContentType.handwritten;
    }
    return DocumentContentType.mixed;
  }

  static ScanEnhanceMode _recommendedMode(
    DocumentContentType type,
    _Stats stats,
    double edgeDensity,
  ) {
    switch (type) {
      case DocumentContentType.photo:
        return ScanEnhanceMode.document;
      case DocumentContentType.certificate:
        return ScanEnhanceMode.magicColor;
      case DocumentContentType.receipt:
      case DocumentContentType.textDocument:
        return stats.mean < 0.45 || stats.contrast < 0.25
            ? ScanEnhanceMode.blackWhite
            : ScanEnhanceMode.document;
      case DocumentContentType.handwritten:
        return ScanEnhanceMode.document;
      case DocumentContentType.idCard:
        return ScanEnhanceMode.magicColor;
      case DocumentContentType.mixed:
        return edgeDensity > 0.08
            ? ScanEnhanceMode.document
            : ScanEnhanceMode.magicColor;
    }
  }

  static double _claheStrength(_Stats stats, double edgeDensity) {
    var strength = 1.0;
    if (stats.contrast < 0.25) strength += 0.35;
    if (edgeDensity > 0.08) strength += 0.15;
    if (stats.mean < 0.4) strength += 0.2;
    return strength.clamp(0.8, 1.8);
  }

  static double _sharpenAmount(_Stats stats, double edgeDensity) {
    if (stats.noise > 0.18) return 0.35;
    if (edgeDensity > 0.1) return 0.75;
    return 0.55;
  }
}

class _Stats {
  const _Stats({
    required this.mean,
    required this.contrast,
    required this.noise,
  });

  final double mean;
  final double contrast;
  final double noise;
}
