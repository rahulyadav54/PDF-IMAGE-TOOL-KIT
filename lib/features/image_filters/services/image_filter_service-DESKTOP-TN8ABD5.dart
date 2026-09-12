import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/services/file_service.dart';
import '../models/filter_options.dart';

final imageFilterServiceProvider =
    Provider<ImageFilterService>((ref) => ImageFilterService(ref));

class ImageFilterResult {
  const ImageFilterResult({
    required this.outputPath,
    required this.fileName,
    required this.fileSizeBytes,
  });

  final String outputPath;
  final String fileName;
  final int fileSizeBytes;
}

class ImageFilterService {
  ImageFilterService(this._ref);

  final Ref _ref;

  Future<ImageFilterResult> apply({
    required String inputPath,
    required FilterOptions options,
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

    var output = img.Image.from(decoded);

    if (options.brightness != 0) {
      output = img.adjustColor(output, brightness: options.brightness / 100);
    }
    if (options.contrast != 0) {
      output = img.adjustColor(output, contrast: options.contrast / 100);
    }
    if (options.saturation != 0) {
      output = img.adjustColor(output, saturation: options.saturation / 100);
    }

    output = switch (options.preset) {
      FilterPreset.none => output,
      FilterPreset.blackWhite => img.grayscale(output),
      FilterPreset.vintage => img.sepia(output, amount: 0.75),
      FilterPreset.vivid => img.adjustColor(output, saturation: 0.35, contrast: 0.15),
      FilterPreset.sharpen => img.convolution(
          output,
          filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
        ),
    };

    final encoded = img.encodeJpg(output, quality: 90);
    final fileName =
        FilenameGenerator.withSuffix(inputPath, 'filtered', newExtension: '.jpg');
    final outputPath =
        await _ref.read(fileServiceProvider).saveToOutput(fileName, encoded);

    return ImageFilterResult(
      outputPath: outputPath,
      fileName: fileName,
      fileSizeBytes: encoded.length,
    );
  }
}
