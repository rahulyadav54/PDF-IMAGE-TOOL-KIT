import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

final pdfPageRenderServiceProvider =
    Provider<PdfPageRenderService>((ref) => PdfPageRenderService());

class PdfPageRenderService {
  static const double baseDpi = 110;

  final Map<String, ui.Image> _cache = {};

  Future<ui.Image?> renderPage({
    required Uint8List pdfBytes,
    required int pageIndex,
    double dpi = baseDpi,
  }) async {
    final cacheKey = '${pdfBytes.length}_${pageIndex}_${dpi.round()}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    Uint8List? pngBytes;
    await for (final raster in Printing.raster(
      pdfBytes,
      pages: [pageIndex],
      dpi: dpi,
    )) {
      pngBytes = await raster.toPng();
      break;
    }

    if (pngBytes == null) return null;

    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    _cache[cacheKey] = frame.image;
    return frame.image;
  }

  void clearCache() => _cache.clear();

  void evictPage(int pageIndex) {
    _cache.removeWhere((key, _) => key.contains('_${pageIndex}_'));
  }
}
