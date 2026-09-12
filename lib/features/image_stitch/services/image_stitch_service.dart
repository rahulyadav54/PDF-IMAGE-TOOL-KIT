import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/models/image_format.dart';
import '../../../shared/services/file_service.dart';
import '../../../shared/services/image_encoding_service.dart';
import '../models/stitch_direction.dart';

final imageStitchServiceProvider =
    Provider<ImageStitchService>((ref) => ImageStitchService(ref));

class ImageStitchResult {
  const ImageStitchResult({
    required this.outputPath,
    required this.fileName,
    required this.outputSizeBytes,
    required this.width,
    required this.height,
    required this.imageCount,
    required this.direction,
  });

  final String outputPath;
  final String fileName;
  final int outputSizeBytes;
  final int width;
  final int height;
  final int imageCount;
  final StitchDirection direction;
}

class ImageStitchService {
  ImageStitchService(this._ref);

  final Ref _ref;

  Future<ImageStitchResult> stitch({
    required List<String> inputPaths,
    required StitchDirection direction,
    int quality = 90,
  }) async {
    if (inputPaths.length < 2) {
      throw const ProcessingException('Select at least 2 images to stitch.');
    }

    final images = <img.Image>[];
    for (final path in inputPaths) {
      final file = File(path);
      if (!await file.exists()) {
        throw const InvalidFileException('One of the selected images no longer exists.');
      }

      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw const InvalidFileException("We couldn't read one of the selected images.");
      }
      images.add(decoded);
    }

    final stitched = direction == StitchDirection.vertical
        ? _stitchVertical(images)
        : _stitchHorizontal(images);

    final encoder = _ref.read(imageEncodingServiceProvider);
    final outputBytes = encoder.encode(stitched, ImageFormat.jpg, quality: quality);

    final fileName = FilenameGenerator.stitchedImage(
      vertical: direction == StitchDirection.vertical,
    );
    final outputPath =
        await _ref.read(fileServiceProvider).saveToOutput(fileName, outputBytes);

    return ImageStitchResult(
      outputPath: outputPath,
      fileName: fileName,
      outputSizeBytes: outputBytes.length,
      width: stitched.width,
      height: stitched.height,
      imageCount: images.length,
      direction: direction,
    );
  }

  img.Image _stitchVertical(List<img.Image> images) {
    final width = images.map((image) => image.width).reduce(math.max);
    var totalHeight = 0;
    final resized = <img.Image>[];

    for (final image in images) {
      final scaled = image.width == width
          ? image
          : img.copyResize(
              image,
              width: width,
              interpolation: img.Interpolation.linear,
            );
      resized.add(scaled);
      totalHeight += scaled.height;
    }

    final canvas = img.Image(width: width, height: totalHeight);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

    var offsetY = 0;
    for (final image in resized) {
      img.compositeImage(canvas, image, dstX: 0, dstY: offsetY);
      offsetY += image.height;
    }

    return canvas;
  }

  img.Image _stitchHorizontal(List<img.Image> images) {
    final height = images.map((image) => image.height).reduce(math.max);
    var totalWidth = 0;
    final resized = <img.Image>[];

    for (final image in images) {
      final scaled = image.height == height
          ? image
          : img.copyResize(
              image,
              height: height,
              interpolation: img.Interpolation.linear,
            );
      resized.add(scaled);
      totalWidth += scaled.width;
    }

    final canvas = img.Image(width: totalWidth, height: height);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

    var offsetX = 0;
    for (final image in resized) {
      img.compositeImage(canvas, image, dstX: offsetX, dstY: 0);
      offsetX += image.width;
    }

    return canvas;
  }
}
