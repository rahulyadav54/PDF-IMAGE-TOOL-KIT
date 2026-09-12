import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/models/image_format.dart';
import '../../../shared/services/file_service.dart';
import '../../../shared/services/image_encoding_service.dart';
import '../models/resize_mode.dart';

final imageResizeServiceProvider =
    Provider<ImageResizeService>((ref) => ImageResizeService(ref));

class ImageResizeRequest {
  const ImageResizeRequest({
    required this.mode,
    required this.lockAspectRatio,
    this.targetWidth,
    this.targetHeight,
    this.percentage = 100,
    this.targetFileSizeKb = 500,
    this.quality = 85,
    this.orientation = ImageOrientation.portrait,
  });

  final ResizeMode mode;
  final bool lockAspectRatio;
  final int? targetWidth;
  final int? targetHeight;
  final int percentage;
  final int targetFileSizeKb;
  final int quality;
  final ImageOrientation orientation;
}

class ImageResizeResult {
  const ImageResizeResult({
    required this.outputPath,
    required this.fileName,
    required this.originalSizeBytes,
    required this.outputSizeBytes,
    required this.originalWidth,
    required this.originalHeight,
    required this.newWidth,
    required this.newHeight,
    required this.format,
    required this.approximateTarget,
  });

  final String outputPath;
  final String fileName;
  final int originalSizeBytes;
  final int outputSizeBytes;
  final int originalWidth;
  final int originalHeight;
  final int newWidth;
  final int newHeight;
  final ImageFormat format;
  final bool approximateTarget;
}

class ImageResizeService {
  ImageResizeService(this._ref);

  final Ref _ref;

  Future<ImageResizeResult> resize({
    required String inputPath,
    required ImageResizeRequest request,
  }) async {
    final file = File(inputPath);
    if (!await file.exists()) {
      throw const InvalidFileException('Image file no longer exists.');
    }

    final sourceFormat = ImageFormat.fromPath(inputPath);
    if (sourceFormat == null) {
      throw const InvalidFileException('Unsupported image format.');
    }

    final outputFormat = sourceFormat.supportsEncoding ? sourceFormat : ImageFormat.jpg;

    final originalSize = await file.length();
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const InvalidFileException("We couldn't read this image.");
    }

    var resized = _resizeImage(decoded, request);
    final encoder = _ref.read(imageEncodingServiceProvider);
    var approximateTarget = false;
    var quality = request.quality.clamp(20, 100);
    Uint8List outputBytes;

    if (request.mode == ResizeMode.targetSize) {
      final encoded = _encodeToTargetSize(
        resized,
        outputFormat,
        request.targetFileSizeKb * 1024,
        encoder,
      );
      resized = encoded.image;
      outputBytes = encoded.bytes;
      quality = encoded.quality;
      approximateTarget = true;
    } else {
      outputBytes = encoder.encode(resized, outputFormat, quality: quality);
    }

    final fileName = outputFormat == sourceFormat
        ? FilenameGenerator.imageResized(inputPath)
        : FilenameGenerator.converted(inputPath, outputFormat.extension);
    final outputPath = await _ref.read(fileServiceProvider).saveToOutput(
      fileName,
      outputBytes,
    );

    return ImageResizeResult(
      outputPath: outputPath,
      fileName: fileName,
      originalSizeBytes: originalSize,
      outputSizeBytes: outputBytes.length,
      originalWidth: decoded.width,
      originalHeight: decoded.height,
      newWidth: resized.width,
      newHeight: resized.height,
      format: outputFormat,
      approximateTarget: approximateTarget,
    );
  }

  img.Image _resizeImage(img.Image image, ImageResizeRequest request) {
    final dimensions = _resolveDimensions(image.width, image.height, request);
    return img.copyResize(
      image,
      width: dimensions.width,
      height: dimensions.height,
      interpolation: img.Interpolation.linear,
    );
  }

  _Dimensions _resolveDimensions(
    int originalWidth,
    int originalHeight,
    ImageResizeRequest request,
  ) {
    switch (request.mode) {
      case ResizeMode.percentage:
        final scale = request.percentage.clamp(1, 200) / 100;
        return _Dimensions(
          width: math.max(1, (originalWidth * scale).round()),
          height: math.max(1, (originalHeight * scale).round()),
        );
      case ResizeMode.targetSize:
        return _Dimensions(width: originalWidth, height: originalHeight);
      case ResizeMode.dimensions:
        final width = request.targetWidth ?? originalWidth;
        final height = request.targetHeight ?? originalHeight;

        if (request.lockAspectRatio) {
          final aspect = originalWidth / originalHeight;
          if (request.targetWidth != null && request.targetHeight == null) {
            return _Dimensions(
              width: width,
              height: math.max(1, (width / aspect).round()),
            );
          }
          if (request.targetHeight != null && request.targetWidth == null) {
            return _Dimensions(
              width: math.max(1, (height * aspect).round()),
              height: height,
            );
          }
          return _fitAspectRatio(originalWidth, originalHeight, width, height);
        }

        return _applyOrientation(
          _Dimensions(width: width, height: height),
          request.orientation,
        );
    }
  }

  _Dimensions _fitAspectRatio(
    int originalWidth,
    int originalHeight,
    int maxWidth,
    int maxHeight,
  ) {
    final aspect = originalWidth / originalHeight;
    var width = maxWidth;
    var height = math.max(1, (width / aspect).round());

    if (height > maxHeight) {
      height = maxHeight;
      width = math.max(1, (height * aspect).round());
    }

    return _Dimensions(width: width, height: height);
  }

  _Dimensions _applyOrientation(_Dimensions size, ImageOrientation orientation) {
    final isLandscape = size.width >= size.height;
    if (orientation == ImageOrientation.landscape && !isLandscape) {
      return _Dimensions(width: size.height, height: size.width);
    }
    if (orientation == ImageOrientation.portrait && isLandscape) {
      return _Dimensions(width: size.height, height: size.width);
    }
    return size;
  }

  _TargetEncodeResult _encodeToTargetSize(
    img.Image image,
    ImageFormat format,
    int targetBytes,
    ImageEncodingService encoder,
  ) {
    var working = image;
    var quality = 85;

    for (var attempt = 0; attempt < 14; attempt++) {
      final bytes = encoder.encode(working, format, quality: quality);
      if (bytes.length <= targetBytes) {
        return _TargetEncodeResult(image: working, bytes: bytes, quality: quality);
      }

      if (format.supportsQuality && quality > 30) {
        quality -= 10;
        continue;
      }

      final scaledWidth = math.max(1, (working.width * 0.85).round());
      final scaledHeight = math.max(1, (working.height * 0.85).round());
      if (scaledWidth == working.width && scaledHeight == working.height) {
        return _TargetEncodeResult(image: working, bytes: bytes, quality: quality);
      }

      working = img.copyResize(
        working,
        width: scaledWidth,
        height: scaledHeight,
        interpolation: img.Interpolation.linear,
      );
      quality = 85;
    }

    final bytes = encoder.encode(working, format, quality: quality);
    return _TargetEncodeResult(image: working, bytes: bytes, quality: quality);
  }
}

class _Dimensions {
  const _Dimensions({required this.width, required this.height});

  final int width;
  final int height;
}

class _TargetEncodeResult {
  const _TargetEncodeResult({
    required this.image,
    required this.bytes,
    required this.quality,
  });

  final img.Image image;
  final Uint8List bytes;
  final int quality;
}
