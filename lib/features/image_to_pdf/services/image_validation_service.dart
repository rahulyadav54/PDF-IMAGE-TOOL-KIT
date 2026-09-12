import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../core/errors/app_exception.dart';
import '../../../shared/services/file_service.dart';

final imageValidationServiceProvider =
    Provider<ImageValidationService>((ref) => ImageValidationService(ref));

class ImageValidationResult {
  const ImageValidationResult({
    required this.fileName,
    required this.fileSizeBytes,
    required this.width,
    required this.height,
  });

  final String fileName;
  final int fileSizeBytes;
  final int width;
  final int height;
}

/// Validates image files before PDF conversion.
class ImageValidationService {
  ImageValidationService(this._ref);

  final Ref _ref;

  static const int maxFileSizeBytes = 50 * 1024 * 1024;

  Future<ImageValidationResult> validate(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const InvalidFileException('File no longer exists.');
    }

    final fileService = _ref.read(fileServiceProvider);
    if (!fileService.isImage(path)) {
      throw const InvalidFileException(
        'Unsupported image format. Try JPG, PNG, WEBP, or BMP.',
      );
    }

    final size = await file.length();
    if (size == 0) {
      throw const InvalidFileException('This image file is empty.');
    }

    if (size > maxFileSizeBytes) {
      throw const ProcessingException(
        'This image is too large to process safely. Try a smaller file.',
      );
    }

    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw const InvalidFileException(
          "We couldn't read this image. The file may be corrupted.",
        );
      }

      return ImageValidationResult(
        fileName: file.uri.pathSegments.last,
        fileSizeBytes: size,
        width: decoded.width,
        height: decoded.height,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw const InvalidFileException(
        "We couldn't open this image. The file may be corrupted or unsupported.",
      );
    }
  }
}
