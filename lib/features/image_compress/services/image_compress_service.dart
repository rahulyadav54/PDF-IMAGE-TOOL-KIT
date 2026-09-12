import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/models/image_format.dart';
import '../../../shared/services/file_service.dart';
import '../../../shared/services/image_encoding_service.dart';

final imageCompressServiceProvider =
    Provider<ImageCompressService>((ref) => ImageCompressService(ref));

class ImageCompressResult {
  const ImageCompressResult({
    required this.outputPath,
    required this.fileName,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.format,
    required this.quality,
  });

  final String outputPath;
  final String fileName;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final ImageFormat format;
  final int quality;
}

class ImageCompressService {
  ImageCompressService(this._ref);

  final Ref _ref;

  int estimateSize(int originalBytes, ImageFormat format, int quality) {
    return _ref.read(imageEncodingServiceProvider).estimateCompressedSize(
      originalBytes,
      format,
      quality,
    );
  }

  Future<ImageCompressResult> compress({
    required String inputPath,
    required int quality,
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

    final encoder = _ref.read(imageEncodingServiceProvider);
    final outputBytes = encoder.encode(decoded, outputFormat, quality: quality);

    final fileName = outputFormat == sourceFormat
        ? FilenameGenerator.imageCompressed(inputPath)
        : FilenameGenerator.converted(inputPath, outputFormat.extension);
    final outputPath = await _ref.read(fileServiceProvider).saveToOutput(
      fileName,
      outputBytes,
    );

    return ImageCompressResult(
      outputPath: outputPath,
      fileName: fileName,
      originalSizeBytes: originalSize,
      compressedSizeBytes: outputBytes.length,
      format: outputFormat,
      quality: quality,
    );
  }
}
