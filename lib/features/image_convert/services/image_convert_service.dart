import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/models/image_format.dart';
import '../../../shared/services/file_service.dart';
import '../../../shared/services/image_encoding_service.dart';

final imageConvertServiceProvider =
    Provider<ImageConvertService>((ref) => ImageConvertService(ref));

class ImageConvertResult {
  const ImageConvertResult({
    required this.outputPath,
    required this.fileName,
    required this.originalSizeBytes,
    required this.outputSizeBytes,
    required this.sourceFormat,
    required this.targetFormat,
  });

  final String outputPath;
  final String fileName;
  final int originalSizeBytes;
  final int outputSizeBytes;
  final ImageFormat sourceFormat;
  final ImageFormat targetFormat;
}

class ImageConvertService {
  ImageConvertService(this._ref);

  final Ref _ref;

  Future<ImageConvertResult> convert({
    required String inputPath,
    required ImageFormat targetFormat,
  }) async {
    final file = File(inputPath);
    if (!await file.exists()) {
      throw const InvalidFileException('Image file no longer exists.');
    }

    final sourceFormat = ImageFormat.fromPath(inputPath);
    if (sourceFormat == null) {
      throw const InvalidFileException('Unsupported image format.');
    }

    final originalSize = await file.length();
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const InvalidFileException("We couldn't read this image.");
    }

    final encoder = _ref.read(imageEncodingServiceProvider);
    final outputBytes = encoder.encode(
      decoded,
      targetFormat,
      quality: targetFormat.supportsQuality ? 90 : 100,
    );

    final fileName = FilenameGenerator.converted(
      inputPath,
      targetFormat.extension,
    );
    final outputPath = await _ref.read(fileServiceProvider).saveToOutput(
      fileName,
      outputBytes,
    );

    return ImageConvertResult(
      outputPath: outputPath,
      fileName: fileName,
      originalSizeBytes: originalSize,
      outputSizeBytes: outputBytes.length,
      sourceFormat: sourceFormat,
      targetFormat: targetFormat,
    );
  }
}
