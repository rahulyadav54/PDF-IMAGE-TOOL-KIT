import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/models/image_format.dart';
import '../../../shared/services/file_service.dart';
import '../../../shared/services/image_encoding_service.dart';
import '../models/id_photo_options.dart';
import '../models/id_photo_preset.dart';

final idPhotoServiceProvider = Provider<IdPhotoService>((ref) => IdPhotoService(ref));

class IdPhotoResult {
  const IdPhotoResult({
    required this.outputPath,
    required this.fileName,
    required this.outputSizeBytes,
    required this.width,
    required this.height,
    required this.preset,
  });

  final String outputPath;
  final String fileName;
  final int outputSizeBytes;
  final int width;
  final int height;
  final IdPhotoPreset preset;
}

class IdPhotoService {
  IdPhotoService(this._ref);

  final Ref _ref;

  Future<IdPhotoResult> create({
    required String inputPath,
    required IdPhotoPreset preset,
    IdPhotoOptions options = const IdPhotoOptions(),
    ImageFormat format = ImageFormat.jpg,
    int quality = 92,
  }) async {
    final rendered = await _render(
      inputPath: inputPath,
      preset: preset,
      options: options,
    );

    final encoder = _ref.read(imageEncodingServiceProvider);
    final outputFormat = format.supportsEncoding ? format : ImageFormat.jpg;
    final outputBytes = encoder.encode(rendered, outputFormat, quality: quality);

    final fileName = FilenameGenerator.idPhoto(preset.id);
    final outputPath =
        await _ref.read(fileServiceProvider).saveToOutput(fileName, outputBytes);

    return IdPhotoResult(
      outputPath: outputPath,
      fileName: fileName,
      outputSizeBytes: outputBytes.length,
      width: rendered.width,
      height: rendered.height,
      preset: preset,
    );
  }

  Future<Uint8List> previewJpeg({
    required String inputPath,
    required IdPhotoPreset preset,
    IdPhotoOptions options = const IdPhotoOptions(),
    int maxSide = 480,
    int quality = 82,
  }) async {
    final rendered = await _render(
      inputPath: inputPath,
      preset: preset,
      options: options,
    );

    final preview = rendered.width > maxSide || rendered.height > maxSide
        ? img.copyResize(
            rendered,
            width: rendered.width >= rendered.height ? maxSide : null,
            height: rendered.height > rendered.width ? maxSide : null,
          )
        : rendered;

    return Uint8List.fromList(img.encodeJpg(preview, quality: quality));
  }

  Future<img.Image> _render({
    required String inputPath,
    required IdPhotoPreset preset,
    required IdPhotoOptions options,
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

    final oriented = img.bakeOrientation(decoded);
    final targetWidth = preset.widthPx(options.dpi);
    final targetHeight = preset.heightPx(options.dpi);

    final cropped = _cropForIdPhoto(
      oriented,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      verticalFocus: options.verticalFocus.clamp(0.0, 1.0),
    );

    final resized = img.copyResize(
      cropped,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.cubic,
    );

    return _applyBackground(resized, options.background);
  }

  img.Image _cropForIdPhoto(
    img.Image image, {
    required int targetWidth,
    required int targetHeight,
    required double verticalFocus,
  }) {
    final targetAspect = targetWidth / targetHeight;
    final sourceAspect = image.width / image.height;

    int cropWidth;
    int cropHeight;

    if (sourceAspect > targetAspect) {
      cropHeight = image.height;
      cropWidth = (image.height * targetAspect).round();
    } else {
      cropWidth = image.width;
      cropHeight = (image.width / targetAspect).round();
    }

    cropWidth = cropWidth.clamp(1, image.width);
    cropHeight = cropHeight.clamp(1, image.height);

    final maxX = image.width - cropWidth;
    final maxY = image.height - cropHeight;
    final x = maxX ~/ 2;
    final y = (maxY * verticalFocus).round().clamp(0, maxY);

    return img.copyCrop(
      image,
      x: x,
      y: y,
      width: cropWidth,
      height: cropHeight,
    );
  }

  img.Image _applyBackground(img.Image image, IdPhotoBackground background) {
    if (background.isOriginal && !image.hasAlpha) {
      return image;
    }

    if (background.isOriginal) {
      final flat = img.Image(width: image.width, height: image.height);
      img.fill(flat, color: img.ColorRgb8(255, 255, 255));
      img.compositeImage(flat, image);
      return flat;
    }

    final flat = img.Image(width: image.width, height: image.height);
    img.fill(
      flat,
      color: img.ColorRgb8(background.red!, background.green!, background.blue!),
    );
    img.compositeImage(flat, image);
    return flat;
  }
}
