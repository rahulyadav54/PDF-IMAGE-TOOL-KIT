import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'temp_file_service.dart';

final thumbnailServiceProvider = Provider<ThumbnailService>((ref) {
  return ThumbnailService(ref);
});

class ThumbnailService {
  ThumbnailService(this._ref);

  final Ref _ref;
  static const int _thumbMaxSide = 160;

  Future<String?> generateThumbnail(String sourcePath) async {
    try {
      final bytes = await File(sourcePath).readAsBytes();
      final thumbnailBytes = await compute(_generateThumbnailBytes, bytes);
      if (thumbnailBytes == null) return null;

      final tempService = _ref.read(tempFileServiceProvider);
      final outputPath = await tempService.createTempFile(extension: '.jpg');
      await File(outputPath).writeAsBytes(thumbnailBytes, flush: true);
      return outputPath;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> generateThumbnails(
    List<String> sourcePaths, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final result = <String, String>{};
    for (var i = 0; i < sourcePaths.length; i++) {
      final path = sourcePaths[i];
      final thumb = await generateThumbnail(path);
      if (thumb != null) result[path] = thumb;
      onProgress?.call(i + 1, sourcePaths.length);
    }
    return result;
  }
}

Uint8List? _generateThumbnailBytes(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  final oriented = img.bakeOrientation(decoded);
  final resized = oriented.width >= oriented.height
      ? img.copyResize(oriented, width: ThumbnailService._thumbMaxSide)
      : img.copyResize(oriented, height: ThumbnailService._thumbMaxSide);

  return Uint8List.fromList(img.encodeJpg(resized, quality: 72));
}
