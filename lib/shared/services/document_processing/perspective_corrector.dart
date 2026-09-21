import 'dart:math' as math;

import 'package:image/image.dart' as img;

import 'document_boundary_detector.dart';

/// Warps a quadrilateral region into a flat rectangle with safe dimensions.
class PerspectiveCorrector {
  const PerspectiveCorrector._();

  static img.Image correct(img.Image source, List<DocumentCorner> corners) {
    if (corners.length != 4) return source;

    final ordered = DocumentBoundaryDetector.orderCorners(corners);
    final topWidth = _distance(ordered[0], ordered[1]);
    final bottomWidth = _distance(ordered[3], ordered[2]);
    final leftHeight = _distance(ordered[0], ordered[3]);
    final rightHeight = _distance(ordered[1], ordered[2]);

    final outWidth = ((topWidth + bottomWidth) / 2).round().clamp(32, source.width * 2);
    final outHeight = ((leftHeight + rightHeight) / 2).round().clamp(32, source.height * 2);

    if (!_isValidOutputSize(source, outWidth, outHeight, ordered)) {
      return source;
    }

    final matrix = _computeHomography(
      [
        DocumentCorner(0, 0),
        DocumentCorner(outWidth.toDouble(), 0),
        DocumentCorner(outWidth.toDouble(), outHeight.toDouble()),
        DocumentCorner(0, outHeight.toDouble()),
      ],
      ordered,
    );

    final output = img.Image(width: outWidth, height: outHeight, numChannels: 3);
    final edgeColor = _estimateBorderColor(source);

    for (var y = 0; y < outHeight; y++) {
      for (var x = 0; x < outWidth; x++) {
        final mapped = _applyMatrix(matrix, x.toDouble(), y.toDouble());
        final sample = _sampleBilinear(source, mapped.x, mapped.y, edgeColor);
        output.setPixelRgba(x, y, sample[0], sample[1], sample[2], 255);
      }
    }

    return output;
  }

  static bool _isValidOutputSize(
    img.Image source,
    int outWidth,
    int outHeight,
    List<DocumentCorner> corners,
  ) {
    if (outWidth < 32 || outHeight < 32) return false;

    final xs = corners.map((c) => c.x);
    final ys = corners.map((c) => c.y);
    final quadArea = _quadArea(corners);
    final imageArea = source.width * source.height;
    if (quadArea < imageArea * 0.08) return false;

    final aspect = outWidth / outHeight;
    if (aspect < 0.15 || aspect > 6.5) return false;

    final maxX = xs.reduce(math.max);
    final minX = xs.reduce(math.min);
    final maxY = ys.reduce(math.max);
    final minY = ys.reduce(math.min);
    if (maxX - minX < source.width * 0.12) return false;
    if (maxY - minY < source.height * 0.12) return false;

    return true;
  }

  static double _quadArea(List<DocumentCorner> corners) {
    var area = 0.0;
    for (var i = 0; i < 4; i++) {
      final a = corners[i];
      final b = corners[(i + 1) % 4];
      area += a.x * b.y - b.x * a.y;
    }
    return area.abs() / 2;
  }

  static List<int> _estimateBorderColor(img.Image source) {
    var r = 0;
    var g = 0;
    var b = 0;
    var count = 0;
    final stepX = math.max(1, source.width ~/ 40);
    final stepY = math.max(1, source.height ~/ 40);

    void sample(int x, int y) {
      final p = source.getPixel(x.clamp(0, source.width - 1), y.clamp(0, source.height - 1));
      r += p.r.toInt();
      g += p.g.toInt();
      b += p.b.toInt();
      count++;
    }

    for (var x = 0; x < source.width; x += stepX) {
      sample(x, 0);
      sample(x, source.height - 1);
    }
    for (var y = 0; y < source.height; y += stepY) {
      sample(0, y);
      sample(source.width - 1, y);
    }

    if (count == 0) return [240, 240, 240];
    return [(r / count).round(), (g / count).round(), (b / count).round()];
  }

  static double _distance(DocumentCorner a, DocumentCorner b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  static List<double> _computeHomography(
    List<DocumentCorner> src,
    List<DocumentCorner> dst,
  ) {
    final a = List.generate(8, (_) => List<double>.filled(8, 0));
    final b = List<double>.filled(8, 0);

    for (var i = 0; i < 4; i++) {
      final sx = src[i].x;
      final sy = src[i].y;
      final dx = dst[i].x;
      final dy = dst[i].y;
      final row = i * 2;
      a[row][0] = sx;
      a[row][1] = sy;
      a[row][2] = 1;
      a[row][6] = -dx * sx;
      a[row][7] = -dx * sy;
      b[row] = dx;

      a[row + 1][3] = sx;
      a[row + 1][4] = sy;
      a[row + 1][5] = 1;
      a[row + 1][6] = -dy * sx;
      a[row + 1][7] = -dy * sy;
      b[row + 1] = dy;
    }

    final h = _solveLinearSystem(a, b);
    return [
      h[0], h[1], h[2],
      h[3], h[4], h[5],
      h[6], h[7], 1,
    ];
  }

  static List<double> _solveLinearSystem(List<List<double>> a, List<double> b) {
    final n = b.length;
    final matrix = List.generate(n, (i) => [...a[i], b[i]]);

    for (var col = 0; col < n; col++) {
      var pivot = col;
      for (var row = col + 1; row < n; row++) {
        if (matrix[row][col].abs() > matrix[pivot][col].abs()) {
          pivot = row;
        }
      }
      final temp = matrix[col];
      matrix[col] = matrix[pivot];
      matrix[pivot] = temp;

      final pivotValue = matrix[col][col];
      if (pivotValue.abs() < 1e-8) continue;

      for (var row = col + 1; row < n; row++) {
        final factor = matrix[row][col] / pivotValue;
        for (var j = col; j <= n; j++) {
          matrix[row][j] -= factor * matrix[col][j];
        }
      }
    }

    final result = List<double>.filled(n, 0);
    for (var row = n - 1; row >= 0; row--) {
      var sum = matrix[row][n];
      for (var col = row + 1; col < n; col++) {
        sum -= matrix[row][col] * result[col];
      }
      final divisor = matrix[row][row];
      result[row] = divisor.abs() < 1e-8 ? 0 : sum / divisor;
    }
    return result;
  }

  static DocumentCorner _applyMatrix(List<double> matrix, double x, double y) {
    final denominator = matrix[6] * x + matrix[7] * y + matrix[8];
    if (denominator.abs() < 1e-8) {
      return DocumentCorner(x, y);
    }
    final mappedX = (matrix[0] * x + matrix[1] * y + matrix[2]) / denominator;
    final mappedY = (matrix[3] * x + matrix[4] * y + matrix[5]) / denominator;
    return DocumentCorner(mappedX, mappedY);
  }

  static List<int> _sampleBilinear(
    img.Image source,
    double x,
    double y,
    List<int> fallback,
  ) {
    if (x < 0 || y < 0 || x > source.width - 1 || y > source.height - 1) {
      return [...fallback, 255];
    }

    x = x.clamp(0.0, source.width - 1.001);
    y = y.clamp(0.0, source.height - 1.001);

    final x0 = x.floor();
    final y0 = y.floor();
    final x1 = math.min(x0 + 1, source.width - 1);
    final y1 = math.min(y0 + 1, source.height - 1);
    final tx = x - x0;
    final ty = y - y0;

    final p00 = source.getPixel(x0, y0);
    final p10 = source.getPixel(x1, y0);
    final p01 = source.getPixel(x0, y1);
    final p11 = source.getPixel(x1, y1);

    int blend(int c00, int c10, int c01, int c11) {
      final top = c00 + (c10 - c00) * tx;
      final bottom = c01 + (c11 - c01) * tx;
      return (top + (bottom - top) * ty).round().clamp(0, 255);
    }

    return [
      blend(p00.r.toInt(), p10.r.toInt(), p01.r.toInt(), p11.r.toInt()),
      blend(p00.g.toInt(), p10.g.toInt(), p01.g.toInt(), p11.g.toInt()),
      blend(p00.b.toInt(), p10.b.toInt(), p01.b.toInt(), p11.b.toInt()),
    ];
  }
}
