import 'dart:math' as math;

import 'package:image/image.dart' as img;

class DocumentCorner {
  const DocumentCorner(this.x, this.y);

  final double x;
  final double y;
}

class DocumentBoundaryResult {
  const DocumentBoundaryResult({
    required this.corners,
    required this.confidence,
  });

  final List<DocumentCorner> corners;
  final double confidence;

  bool get isReliable => confidence >= 0.62 && corners.length == 4;
}

/// Detects document quadrilaterals from edge density in corner regions.
class DocumentBoundaryDetector {
  const DocumentBoundaryDetector._();

  static const int _sampleWidth = 420;
  static const double _confidenceThreshold = 0.62;

  static double get confidenceThreshold => _confidenceThreshold;

  static DocumentBoundaryResult detect(img.Image source) {
    final sample = img.copyResize(source, width: _sampleWidth);
    final scaleX = source.width / sample.width;
    final scaleY = source.height / sample.height;
    final gray = img.grayscale(img.gaussianBlur(sample, radius: 2));
    final edges = _edgeMap(gray);

    final corners = <DocumentCorner>[
      _findCorner(edges, 0, 0, sample.width * 0.48, sample.height * 0.48, preferMin: true),
      _findCorner(
        edges,
        sample.width * 0.52,
        0,
        sample.width.toDouble(),
        sample.height * 0.48,
        preferMin: false,
      ),
      _findCorner(
        edges,
        sample.width * 0.52,
        sample.height * 0.52,
        sample.width.toDouble(),
        sample.height.toDouble(),
        preferMin: false,
      ),
      _findCorner(
        edges,
        0,
        sample.height * 0.52,
        sample.width * 0.48,
        sample.height.toDouble(),
        preferMin: true,
      ),
    ];

    final scaledCorners = corners
        .map((c) => DocumentCorner(c.x * scaleX, c.y * scaleY))
        .toList();

    final confidence = _scoreQuadrilateral(
      scaledCorners,
      source.width,
      source.height,
      edges,
    );

    return DocumentBoundaryResult(
      corners: scaledCorners,
      confidence: confidence,
    );
  }

  static DocumentCorner _findCorner(
    List<List<double>> edges,
    double x0,
    double y0,
    double x1,
    double y1, {
    required bool preferMin,
  }) {
    final left = x0.round().clamp(0, edges[0].length - 1);
    final top = y0.round().clamp(0, edges.length - 1);
    final right = x1.round().clamp(left + 1, edges[0].length);
    final bottom = y1.round().clamp(top + 1, edges.length);

    var bestX = preferMin ? left : right - 1;
    var bestY = preferMin ? top : bottom - 1;
    var bestScore = -1.0;

    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        final edge = edges[y][x];
        final cornerBias = preferMin
            ? (1 - x / edges[0].length) + (1 - y / edges.length)
            : (x / edges[0].length) + (1 - y / edges.length);
        final score = edge + cornerBias * 0.15;
        if (score > bestScore) {
          bestScore = score;
          bestX = x;
          bestY = y;
        }
      }
    }

    return DocumentCorner(bestX.toDouble(), bestY.toDouble());
  }

  static List<List<double>> _edgeMap(img.Image gray) {
    final edges = List.generate(
      gray.height,
      (_) => List<double>.filled(gray.width, 0),
    );

    for (var y = 1; y < gray.height - 1; y++) {
      for (var x = 1; x < gray.width - 1; x++) {
        final center = gray.getPixel(x, y).r.toDouble();
        final right = gray.getPixel(x + 1, y).r.toDouble();
        final down = gray.getPixel(x, y + 1).r.toDouble();
        edges[y][x] = ((center - right).abs() + (center - down).abs()) / 255;
      }
    }
    return edges;
  }

  static double _scoreQuadrilateral(
    List<DocumentCorner> corners,
    int width,
    int height,
    List<List<double>> edges,
  ) {
    if (corners.length != 4) return 0;

    final xs = corners.map((c) => c.x).toList();
    final ys = corners.map((c) => c.y).toList();
    final minX = xs.reduce(math.min);
    final maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min);
    final maxY = ys.reduce(math.max);

    final quadWidth = maxX - minX;
    final quadHeight = maxY - minY;
    if (quadWidth < width * 0.18 || quadHeight < height * 0.18) return 0;

    final areaRatio = (quadWidth * quadHeight) / (width * height);
    if (areaRatio < 0.22 || areaRatio > 0.96) return 0;

    final aspect = quadWidth / quadHeight;
    if (aspect < 0.25 || aspect > 4.0) return 0;

    final cornerSpread = _cornerDistanceScore(corners, width, height);
    final edgeInside = _edgeDensityInside(edges, corners);
    final rectangularity = _rectangularityScore(corners);

    return (areaRatio * 0.25 +
            cornerSpread * 0.25 +
            edgeInside * 0.25 +
            rectangularity * 0.25)
        .clamp(0.0, 1.0);
  }

  static double _cornerDistanceScore(
    List<DocumentCorner> corners,
    int width,
    int height,
  ) {
    final targets = [
      DocumentCorner(0, 0),
      DocumentCorner(width.toDouble(), 0),
      DocumentCorner(width.toDouble(), height.toDouble()),
      DocumentCorner(0, height.toDouble()),
    ];

    var total = 0.0;
    for (var i = 0; i < 4; i++) {
      final dx = corners[i].x - targets[i].x;
      final dy = corners[i].y - targets[i].y;
      final dist = math.sqrt(dx * dx + dy * dy);
      final maxDist = math.sqrt(width * width + height * height);
      total += 1 - (dist / maxDist).clamp(0, 1);
    }
    return total / 4;
  }

  static double _edgeDensityInside(
    List<List<double>> edges,
    List<DocumentCorner> corners,
  ) {
    final minX = corners.map((c) => c.x).reduce(math.min).round();
    final maxX = corners.map((c) => c.x).reduce(math.max).round();
    final minY = corners.map((c) => c.y).reduce(math.min).round();
    final maxY = corners.map((c) => c.y).reduce(math.max).round();
    var sum = 0.0;
    var count = 0;

    for (var y = minY; y < maxY && y < edges.length; y++) {
      for (var x = minX; x < maxX && x < edges[y].length; x++) {
        sum += edges[y][x];
        count++;
      }
    }

    return count == 0 ? 0 : (sum / count).clamp(0, 1);
  }

  static double _rectangularityScore(List<DocumentCorner> corners) {
    double dist(DocumentCorner a, DocumentCorner b) {
      final dx = a.x - b.x;
      final dy = a.y - b.y;
      return math.sqrt(dx * dx + dy * dy);
    }

    final top = dist(corners[0], corners[1]);
    final right = dist(corners[1], corners[2]);
    final bottom = dist(corners[2], corners[3]);
    final left = dist(corners[3], corners[0]);
    final widthAvg = (top + bottom) / 2;
    final heightAvg = (left + right) / 2;
    if (widthAvg <= 0 || heightAvg <= 0) return 0;

    final widthDiff = (top - bottom).abs() / widthAvg;
    final heightDiff = (left - right).abs() / heightAvg;
    return (1 - ((widthDiff + heightDiff) / 2)).clamp(0, 1);
  }
}
