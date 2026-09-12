import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../models/image_format.dart';

final imageEncodingServiceProvider =
    Provider<ImageEncodingService>((ref) => ImageEncodingService());

/// Encodes decoded images into supported output formats.
class ImageEncodingService {
  Uint8List encode(
    img.Image image,
    ImageFormat format, {
    int quality = 90,
  }) {
    final prepared = _prepareForFormat(image, format);

    switch (format) {
      case ImageFormat.jpg:
        return Uint8List.fromList(
          img.encodeJpg(prepared, quality: quality.clamp(1, 100)),
        );
      case ImageFormat.png:
        final level = ((100 - quality) / 11).round().clamp(0, 9);
        return Uint8List.fromList(img.encodePng(prepared, level: level));
      case ImageFormat.webp:
        throw UnsupportedError('WEBP export is not supported on-device.');
      case ImageFormat.bmp:
        return Uint8List.fromList(img.encodeBmp(prepared));
      case ImageFormat.gif:
        return Uint8List.fromList(img.encodeGif(prepared));
    }
  }

  /// Rough size estimate for lossy formats before processing.
  int estimateCompressedSize(int originalBytes, ImageFormat format, int quality) {
    if (!format.supportsQuality) {
      return (originalBytes * 0.92).round();
    }
    final ratio = (quality / 100).clamp(0.2, 1.0);
    return (originalBytes * ratio).round();
  }

  img.Image _prepareForFormat(img.Image image, ImageFormat format) {
    if (format == ImageFormat.jpg && image.hasAlpha) {
      final flat = img.Image(width: image.width, height: image.height);
      img.fill(flat, color: img.ColorRgb8(255, 255, 255));
      img.compositeImage(flat, image);
      return flat;
    }
    return image;
  }
}
