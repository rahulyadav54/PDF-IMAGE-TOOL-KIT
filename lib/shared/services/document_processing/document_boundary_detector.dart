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

  bool get isReliable => confidence >= 0.28 && corners.length == 4;
}

class _Point {
  const _Point(this.x, this.y);

  final double x;
  final double y;
}

/// Detects document quadrilaterals using luminance borders, hull, and edges.
class DocumentBoundaryDetector {
  const DocumentBoundaryDetector._();

  static const int _sampleWidth = 520;
  static const double _confidenceThreshold = 0.28;

  static double get confidenceThreshold => _confidenceThreshold;

  static DocumentBoundaryResult detect(img.Image source) {
    final sample = img.copyResize(source, width: _sampleWidth);
    final scaleX = source.width / sample.width;
    final scaleY = source.height / sample.height;
    final gray = img.grayscale(img.gaussianBlur(sample, radius: 1));
    final edges = _edgeMap(gray);
    final sw = sample.width.toDouble();
    final sh = sample.height.toDouble();

    DocumentBoundaryResult? best;

    void consider(List<DocumentCorner> corners, {double bonus = 0}) {
      if (corners.length != 4 || !_isConvexQuad(corners)) return;
      final confidence = _scoreQuadrilateral(corners, sw, sh, edges) + bonus;
      final result = DocumentBoundaryResult(
        corners: orderCorners(corners),
        confidence: confidence.clamp(0.0, 1.0),
      );
      if (best == null || result.confidence > best!.confidence) {
        best = result;
      }
    }

    final luminance = _detectByLuminanceBorder(gray);
    if (luminance != null) {
      consider(luminance, bonus: 0.08);
    }

    final hullCorners = _detectByConvexHull(gray, edges);
    if (hullCorners != null) {
      consider(hullCorners);
    }

    final edgeScan = _detectByEdgeScan(gray, edges);
    if (edgeScan != null) {
      consider(edgeScan);
    }

    final quadrant = _detectByQuadrants(sample, edges);
    consider(quadrant.corners);

    if (best == null) {
      return DocumentBoundaryResult(
        corners: const [],
        confidence: 0,
      );
    }

    final scaled = best!.corners
        .map((c) => DocumentCorner(c.x * scaleX, c.y * scaleY))
        .toList();

    return DocumentBoundaryResult(
      corners: orderCorners(scaled),
      confidence: best!.confidence,
    );
  }

  /// Orders corners as top-left, top-right, bottom-right, bottom-left.
  static List<DocumentCorner> orderCorners(List<DocumentCorner> corners) {
    if (corners.length != 4) return corners;

    final tl = corners.reduce(
      (a, b) => (a.x + a.y) < (b.x + b.y) ? a : b,
    );
    final tr = corners.reduce(
      (a, b) => (a.x - a.y) > (b.x - b.y) ? a : b,
    );
    final br = corners.reduce(
      (a, b) => (a.x + a.y) > (b.x + b.y) ? a : b,
    );
    final bl = corners.reduce(
      (a, b) => (a.x - a.y) < (b.x - b.y) ? a : b,
    );

    return [tl, tr, br, bl];
  }

  /// Expands corners slightly outward so the full page is included.
  static List<DocumentCorner> expandCorners(
    List<DocumentCorner> corners,
    int imageWidth,
    int imageHeight, {
    double fraction = 0.012,
  }) {
    if (corners.length != 4) return corners;

    final cx = corners.map((c) => c.x).reduce((a, b) => a + b) / 4;
    final cy = corners.map((c) => c.y).reduce((a, b) => a + b) / 4;

    return corners
        .map((c) {
          final dx = c.x - cx;
          final dy = c.y - cy;
          return DocumentCorner(
            (cx + dx * (1 + fraction)).clamp(0, imageWidth - 1.0),
            (cy + dy * (1 + fraction)).clamp(0, imageHeight - 1.0),
          );
        })
        .toList();
  }

  static bool isValidQuad(
    List<DocumentCorner> corners,
    int width,
    int height,
  ) {
    if (corners.length != 4 || !_isConvexQuad(corners)) return false;

    for (final c in corners) {
      if (c.x < -2 || c.y < -2 || c.x > width + 2 || c.y > height + 2) {
        return false;
      }
    }

    final xs = corners.map((c) => c.x);
    final ys = corners.map((c) => c.y);
    final quadWidth = xs.reduce(math.max) - xs.reduce(math.min);
    final quadHeight = ys.reduce(math.max) - ys.reduce(math.min);
    final areaRatio = (quadWidth * quadHeight) / (width * height);
    return areaRatio >= 0.12 && areaRatio <= 0.99;
  }

  /// Finds paper borders by luminance change from desk/background.
  static List<DocumentCorner>? _detectByLuminanceBorder(img.Image gray) {
    final w = gray.width;
    final h = gray.height;

    final rowMean = List<double>.generate(h, (y) {
      var sum = 0.0;
      for (var x = (w * 0.08).round(); x < w * 0.92; x++) {
        sum += gray.getPixel(x, y).r;
      }
      return sum / (w * 0.84);
    });

    final colMean = List<double>.generate(w, (x) {
      var sum = 0.0;
      for (var y = (h * 0.08).round(); y < h * 0.92; y++) {
        sum += gray.getPixel(x, y).r;
      }
      return sum / (h * 0.84);
    });

    int scanEdge(List<double> profile, bool fromStart) {
      final limit = (profile.length * 0.48).round();
      final bgSamples = fromStart
          ? profile.sublist(0, math.min(6, profile.length))
          : profile.sublist(math.max(0, profile.length - 6));
      final bg = bgSamples.reduce((a, b) => a + b) / bgSamples.length;

      if (fromStart) {
        for (var i = 2; i < limit; i++) {
          final value = profile[i];
          final grad = (profile[i] - profile[i - 1]).abs();
          if ((value - bg).abs() > 7 && grad > 3.5) return i;
        }
        return 0;
      }

      for (var i = profile.length - 3; i >= profile.length - limit; i--) {
        final value = profile[i];
        final grad = (profile[i] - profile[i + 1]).abs();
        if ((value - bg).abs() > 7 && grad > 3.5) return i;
      }
      return profile.length - 1;
    }

    final top = scanEdge(rowMean, true);
    final bottom = scanEdge(rowMean, false);
    final left = scanEdge(colMean, true);
    final right = scanEdge(colMean, false);

    if (right - left < w * 0.22 || bottom - top < h * 0.22) return null;

    return [
      DocumentCorner(left.toDouble(), top.toDouble()),
      DocumentCorner(right.toDouble(), top.toDouble()),
      DocumentCorner(right.toDouble(), bottom.toDouble()),
      DocumentCorner(left.toDouble(), bottom.toDouble()),
    ];
  }

  static List<DocumentCorner>? _detectByEdgeScan(
    img.Image gray,
    List<List<double>> edges,
  ) {
    final w = gray.width;
    final h = gray.height;

    int scanHorizontal(bool fromTop) {
      final rows = fromTop
          ? List.generate((h * 0.48).round(), (i) => i)
          : List.generate((h * 0.48).round(), (i) => h - 1 - i);
      for (final y in rows) {
        var edgeSum = 0.0;
        for (var x = 1; x < w - 1; x++) {
          edgeSum += edges[y][x];
        }
        if (edgeSum / w > 0.06) return y;
      }
      return fromTop ? 0 : h - 1;
    }

    int scanVertical(bool fromLeft) {
      final cols = fromLeft
          ? List.generate((w * 0.48).round(), (i) => i)
          : List.generate((w * 0.48).round(), (i) => w - 1 - i);
      for (final x in cols) {
        var edgeSum = 0.0;
        for (var y = 1; y < h - 1; y++) {
          edgeSum += edges[y][x];
        }
        if (edgeSum / h > 0.06) return x;
      }
      return fromLeft ? 0 : w - 1;
    }

    final top = scanHorizontal(true);
    final bottom = scanHorizontal(false);
    final left = scanVertical(true);
    final right = scanVertical(false);

    if (right - left < w * 0.22 || bottom - top < h * 0.22) return null;

    return [
      DocumentCorner(left.toDouble(), top.toDouble()),
      DocumentCorner(right.toDouble(), top.toDouble()),
      DocumentCorner(right.toDouble(), bottom.toDouble()),
      DocumentCorner(left.toDouble(), bottom.toDouble()),
    ];
  }

  static List<DocumentCorner>? _detectByConvexHull(
    img.Image gray,
    List<List<double>> edges,
  ) {
    final points = <_Point>[];
    final step = math.max(1, (gray.width / 120).round());
    const threshold = 0.08;

    for (var y = step; y < gray.height - step; y += step) {
      for (var x = step; x < gray.width - step; x += step) {
        if (edges[y][x] > threshold) {
          points.add(_Point(x.toDouble(), y.toDouble()));
        }
      }
    }

    if (points.length < 20) return null;

    final hull = _convexHull(points);
    if (hull.length < 4) return null;

    return _quadFromHullByAngle(hull);
  }

  static List<DocumentCorner> _quadFromHullByAngle(List<_Point> hull) {
    if (hull.length == 4) {
      return hull
          .map((p) => DocumentCorner(p.x, p.y))
          .toList();
    }

    var cx = 0.0;
    var cy = 0.0;
    for (final p in hull) {
      cx += p.x;
      cy += p.y;
    }
    cx /= hull.length;
    cy /= hull.length;

    final sorted = List<_Point>.from(hull);
    sorted.sort((a, b) {
      final aa = math.atan2(a.y - cy, a.x - cx);
      final bb = math.atan2(b.y - cy, b.x - cx);
      return aa.compareTo(bb);
    });

    final n = sorted.length;
    final picks = [0, n ~/ 4, n ~/ 2, (3 * n) ~/ 4];
    return picks
        .map((i) => DocumentCorner(sorted[i].x, sorted[i].y))
        .toList();
  }

  static DocumentBoundaryResult _detectByQuadrants(
    img.Image sample,
    List<List<double>> edges,
  ) {
    final corners = <DocumentCorner>[
      _findCorner(edges, 0, 0, sample.width * 0.5, sample.height * 0.5, preferMin: true),
      _findCorner(
        edges,
        sample.width * 0.5,
        0,
        sample.width.toDouble(),
        sample.height * 0.5,
        preferMin: false,
      ),
      _findCorner(
        edges,
        sample.width * 0.5,
        sample.height * 0.5,
        sample.width.toDouble(),
        sample.height.toDouble(),
        preferMin: false,
      ),
      _findCorner(
        edges,
        0,
        sample.height * 0.5,
        sample.width * 0.5,
        sample.height.toDouble(),
        preferMin: true,
      ),
    ];

    final confidence = _scoreQuadrilateral(
      orderCorners(corners),
      sample.width.toDouble(),
      sample.height.toDouble(),
      edges,
    );

    return DocumentBoundaryResult(corners: orderCorners(corners), confidence: confidence);
  }

  static List<_Point> _convexHull(List<_Point> points) {
    if (points.length < 3) return points;

    final sorted = List<_Point>.from(points);
    sorted.sort((a, b) {
      final cmp = a.x.compareTo(b.x);
      return cmp != 0 ? cmp : a.y.compareTo(b.y);
    });

    double cross(_Point o, _Point a, _Point b) {
      return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);
    }

    final lower = <_Point>[];
    for (final p in sorted) {
      while (lower.length >= 2 &&
          cross(lower[lower.length - 2], lower.last, p) <= 0) {
        lower.removeLast();
      }
      lower.add(p);
    }

    final upper = <_Point>[];
    for (var i = sorted.length - 1; i >= 0; i--) {
      final p = sorted[i];
      while (upper.length >= 2 &&
          cross(upper[upper.length - 2], upper.last, p) <= 0) {
        upper.removeLast();
      }
      upper.add(p);
    }

    lower.removeLast();
    upper.removeLast();
    return [...lower, ...upper];
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
            : (x / edges[0].length) + (y / edges.length);
        final score = edge + cornerBias * 0.2;
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
        final tl = gray.getPixel(x - 1, y - 1).r.toDouble();
        final tc = gray.getPixel(x, y - 1).r.toDouble();
        final tr = gray.getPixel(x + 1, y - 1).r.toDouble();
        final cl = gray.getPixel(x - 1, y).r.toDouble();
        final cr = gray.getPixel(x + 1, y).r.toDouble();
        final bl = gray.getPixel(x - 1, y + 1).r.toDouble();
        final bc = gray.getPixel(x, y + 1).r.toDouble();
        final br = gray.getPixel(x + 1, y + 1).r.toDouble();

        final gx = -tl - 2 * cl - bl + tr + 2 * cr + br;
        final gy = -tl - 2 * tc - tr + bl + 2 * bc + br;
        edges[y][x] = math.sqrt(gx * gx + gy * gy) / (255 * 4);
      }
    }
    return edges;
  }

  static bool _isConvexQuad(List<DocumentCorner> corners) {
    if (corners.length != 4) return false;

    double cross(int i) {
      final a = corners[i];
      final b = corners[(i + 1) % 4];
      final c = corners[(i + 2) % 4];
      return (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);
    }

    final c0 = cross(0);
    final c1 = cross(1);
    if (c0 == 0 || c1 == 0) return false;
    return (c0 > 0) == (c1 > 0);
  }

  static double _scoreQuadrilateral(
    List<DocumentCorner> corners,
    double width,
    double height,
    List<List<double>> edges,
  ) {
    if (corners.length != 4 || !_isConvexQuad(corners)) return 0;

    final xs = corners.map((c) => c.x);
    final ys = corners.map((c) => c.y);
    final minX = xs.reduce(math.min);
    final maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min);
    final maxY = ys.reduce(math.max);

    final quadWidth = maxX - minX;
    final quadHeight = maxY - minY;
    if (quadWidth < width * 0.12 || quadHeight < height * 0.12) return 0;

    final areaRatio = (quadWidth * quadHeight) / (width * height);
    if (areaRatio < 0.14 || areaRatio > 0.98) return 0;

    final aspect = quadWidth / quadHeight;
    if (aspect < 0.18 || aspect > 5.5) return 0;

    final edgeInside = _edgeDensityOnPerimeter(edges, corners);
    final rectangularity = _rectangularityScore(corners);

    return (areaRatio * 0.25 + edgeInside * 0.4 + rectangularity * 0.35)
        .clamp(0.0, 1.0);
  }

  static double _edgeDensityOnPerimeter(
    List<List<double>> edges,
    List<DocumentCorner> corners,
  ) {
    var sum = 0.0;
    var count = 0;

    for (var i = 0; i < 4; i++) {
      final a = corners[i];
      final b = corners[(i + 1) % 4];
      final steps = math.max(
        8,
        (math.sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)) / 3)
            .round(),
      );
      for (var s = 0; s <= steps; s++) {
        final t = s / steps;
        final x = (a.x + (b.x - a.x) * t).round();
        final y = (a.y + (b.y - a.y) * t).round();
        if (x >= 0 && y >= 0 && y < edges.length && x < edges[y].length) {
          sum += edges[y][x];
          count++;
        }
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
