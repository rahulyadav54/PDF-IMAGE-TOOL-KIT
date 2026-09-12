import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/services/file_service.dart';
import '../models/watermark_options.dart';

final imageWatermarkServiceProvider =
    Provider<ImageWatermarkService>((ref) => ImageWatermarkService(ref));

class ImageWatermarkResult {
  const ImageWatermarkResult({
    required this.outputPath,
    required this.fileName,
    required this.fileSizeBytes,
  });

  final String outputPath;
  final String fileName;
  final int fileSizeBytes;
}

class ImageWatermarkService {
  ImageWatermarkService(this._ref);

  final Ref _ref;

  Future<ImageWatermarkResult> apply({
    required String inputPath,
    required WatermarkOptions options,
  }) async {
    final file = File(inputPath);
    if (!await file.exists()) {
      throw const InvalidFileException('Image file no longer exists.');
    }

    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const InvalidFileException("We couldn't read this image.");
    }

    final output = img.Image.from(decoded);
    final alpha = (options.opacity.clamp(0.05, 1.0) * 255).round();

    if (options.mode == WatermarkMode.text) {
      _drawTextWatermark(output, options.text, alpha, options.position, options.scale);
    } else {
      final logoPath = options.logoPath;
      if (logoPath == null || !await File(logoPath).exists()) {
        throw const InvalidFileException('Choose a logo image for the watermark.');
      }
      final logoBytes = await File(logoPath).readAsBytes();
      final logo = img.decodeImage(logoBytes);
      if (logo == null) {
        throw const InvalidFileException("We couldn't read the logo image.");
      }
      _drawImageWatermark(output, logo, alpha, options.position, options.scale);
    }

    final encoded = img.encodePng(output);
    final fileName =
        FilenameGenerator.withSuffix(inputPath, 'watermarked', newExtension: '.png');
    final outputPath =
        await _ref.read(fileServiceProvider).saveToOutput(fileName, encoded);

    return ImageWatermarkResult(
      outputPath: outputPath,
      fileName: fileName,
      fileSizeBytes: encoded.length,
    );
  }

  void _drawTextWatermark(
    img.Image canvas,
    String text,
    int alpha,
    WatermarkPosition position,
    double scale,
  ) {
    final font = img.arial24;
    final fontHeight = (font.lineHeight * scale).round();
    final textWidth = (text.length * font.size * 0.55 * scale).round();
    final offset = _offsetFor(canvas, textWidth, fontHeight, position, padding: 16);
    img.drawString(
      canvas,
      text,
      font: font,
      x: offset.x.round(),
      y: offset.y.round(),
      color: img.ColorRgba8(255, 255, 255, alpha),
    );
    img.drawString(
      canvas,
      text,
      font: font,
      x: offset.x.round() + 1,
      y: offset.y.round() + 1,
      color: img.ColorRgba8(0, 0, 0, (alpha * 0.6).round()),
    );
  }

  void _drawImageWatermark(
    img.Image canvas,
    img.Image logo,
    int alpha,
    WatermarkPosition position,
    double scale,
  ) {
    final minSide = canvas.width < canvas.height ? canvas.width : canvas.height;
    final maxSide = (minSide * 0.25 * scale).round();
    final resized = logo.width > logo.height
        ? img.copyResize(logo, width: maxSide)
        : img.copyResize(logo, height: maxSide);

    final tinted = img.Image.from(resized);
    for (var y = 0; y < tinted.height; y++) {
      for (var x = 0; x < tinted.width; x++) {
        final pixel = tinted.getPixel(x, y);
        tinted.setPixel(
          x,
          y,
          img.ColorRgba8(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), alpha),
        );
      }
    }

    final offset = _offsetFor(
      canvas,
      tinted.width,
      tinted.height,
      position,
      padding: 12,
    );
    img.compositeImage(canvas, tinted, dstX: offset.x.round(), dstY: offset.y.round());
  }

  ({double x, double y}) _offsetFor(
    img.Image canvas,
    int overlayWidth,
    int overlayHeight,
    WatermarkPosition position, {
    required int padding,
  }) {
    return switch (position) {
      WatermarkPosition.topLeft => (x: padding.toDouble(), y: padding.toDouble()),
      WatermarkPosition.topRight => (
          x: (canvas.width - overlayWidth - padding).toDouble(),
          y: padding.toDouble(),
        ),
      WatermarkPosition.center => (
          x: ((canvas.width - overlayWidth) / 2).toDouble(),
          y: ((canvas.height - overlayHeight) / 2).toDouble(),
        ),
      WatermarkPosition.bottomLeft => (
          x: padding.toDouble(),
          y: (canvas.height - overlayHeight - padding).toDouble(),
        ),
      WatermarkPosition.bottomRight => (
          x: (canvas.width - overlayWidth - padding).toDouble(),
          y: (canvas.height - overlayHeight - padding).toDouble(),
        ),
    };
  }
}
