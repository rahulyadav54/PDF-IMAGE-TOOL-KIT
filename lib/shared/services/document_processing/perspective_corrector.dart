import 'dart:math' as math;

import 'package:image/image.dart' as img;

import 'document_boundary_detector.dart';

/// Warps a quadrilateral region into a flat rectangle.
class PerspectiveCorrector {
  const PerspectiveCorrector._();

  static img.Image correct(img.Image source, List<DocumentCorner> corners) {
    if (corners.length != 4) return source;

    final topWidth = _distance(corners[0], corners[1]);
    final bottomWidth = _distance(corners[2], corners[3]);
    final leftHeight = _distance(corners[0], corners[3]);
    final rightHeight = _distance(corners[1], corners[2]);

    final outWidth = math.max(topWidth, bottomWidth).round().clamp(32, source.width * 2);
    final outHeight = math.max(leftHeight, rightHeight).round().clamp(32, source.height * 2);

    final matrix = _computeHomography(
      corners,
      [
        DocumentCorner(0, 0),
        DocumentCorner(outWidth.toDouble(), 0),
        DocumentCorner(outWidth.toDouble(), outHeight.toDouble()),
        DocumentCorner(0, outHeight.toDouble()),
      ],
    );

    final output = img.Image(width: outWidth, height: outHeight);
    for (var y = 0; y < outHeight; y++) {
      for (var x = 0; x < outWidth; x++) {
        final mapped = _applyMatrix(matrix, x.toDouble(), y.toDouble());
        final sample = _sampleBilinear(source, mapped.x, mapped.y);
        output.setPixelRgba(x, y, sample[0], sample[1], sample[2], sample[3]);
      }
    }

    return output;
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
    final denominator =
        matrix[6] * x + matrix[7] * y + matrix[8];
    if (denominator.abs() < 1e-8) {
      return DocumentCorner(x, y);
    }
    final mappedX = (matrix[0] * x + matrix[1] * y + matrix[2]) / denominator;
    final mappedY = (matrix[3] * x + matrix[4] * y + matrix[5]) / denominator;
    return DocumentCorner(mappedX, mappedY);
  }

  static List<int> _sampleBilinear(img.Image source, double x, double y) {
    if (x < 0 || y < 0 || x >= source.width - 1 || y >= source.height - 1) {
      return [255, 255, 255, 255];
    }

    final x0 = x.floor();
    final y0 = y.floor();
    final x1 = x0 + 1;
    final y1 = y0 + 1;
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
      blend(p00.a.toInt(), p10.a.toInt(), p01.a.toInt(), p11.a.toInt()),
    ];
  }
}
