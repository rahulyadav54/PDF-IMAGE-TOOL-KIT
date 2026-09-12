import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import 'document_image_analyzer.dart';

final scanQualityServiceProvider =
    Provider<ScanQualityService>((ref) => const ScanQualityService());

class ScanQualityIndicator {
  const ScanQualityIndicator({
    required this.label,
    required this.passed,
    this.warning,
  });

  final String label;
  final bool passed;
  final String? warning;
}

class ScanQualityReport {
  const ScanQualityReport({
    required this.score,
    required this.indicators,
    required this.shouldRetake,
  });

  final int score;
  final List<ScanQualityIndicator> indicators;
  final bool shouldRetake;

  String get summary {
    if (score >= 85) return 'Excellent scan quality';
    if (score >= 70) return 'Good scan quality';
    if (score >= 50) return 'Fair scan quality';
    return 'Poor scan quality';
  }
}

/// Evaluates scan quality for user feedback before accepting a page.
class ScanQualityService {
  const ScanQualityService();

  Future<ScanQualityReport> analyze(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const ScanQualityReport(
        score: 0,
        indicators: [
          ScanQualityIndicator(
            label: 'Could not read image',
            passed: false,
          ),
        ],
        shouldRetake: true,
      );
    }

    final analysis = DocumentImageAnalyzer.analyze(decoded);
    final blurScore = _estimateSharpness(decoded);
    final indicators = <ScanQualityIndicator>[
      ScanQualityIndicator(
        label: 'Document detected',
        passed: analysis.edgeDensity > 0.02,
        warning: analysis.edgeDensity <= 0.02 ? 'Edges not clear' : null,
      ),
      ScanQualityIndicator(
        label: 'Good lighting',
        passed: analysis.meanBrightness > 80 && analysis.meanBrightness < 220,
        warning: analysis.meanBrightness <= 80
            ? 'Too dark'
            : analysis.meanBrightness >= 220
                ? 'Too bright'
                : null,
      ),
      ScanQualityIndicator(
        label: 'Sharp text',
        passed: blurScore >= 0.35,
        warning: blurScore < 0.35 ? 'Slight blur — hold steady' : null,
      ),
      ScanQualityIndicator(
        label: 'Good framing',
        passed: analysis.contrast > 0.08,
        warning: analysis.contrast <= 0.08 ? 'Low contrast' : null,
      ),
    ];

    var score = 100;
    for (final indicator in indicators) {
      if (!indicator.passed) score -= 18;
    }
    if (analysis.shadowIntensity > 0.55) score -= 10;
    if (analysis.noiseLevel > 0.12) score -= 8;
    score = score.clamp(0, 100);

    return ScanQualityReport(
      score: score,
      indicators: indicators,
      shouldRetake: score < 45,
    );
  }

  double _estimateSharpness(img.Image source) {
    final sample = img.grayscale(img.copyResize(source, width: 200));
    var laplacian = 0.0;
    var count = 0;

    for (var y = 1; y < sample.height - 1; y++) {
      for (var x = 1; x < sample.width - 1; x++) {
        final c = sample.getPixel(x, y).r;
        final neighbors = sample.getPixel(x - 1, y).r +
            sample.getPixel(x + 1, y).r +
            sample.getPixel(x, y - 1).r +
            sample.getPixel(x, y + 1).r;
        laplacian += (4 * c - neighbors).abs();
        count++;
      }
    }

    if (count == 0) return 0;
    return (laplacian / count / 255).clamp(0.0, 1.0);
  }
}
