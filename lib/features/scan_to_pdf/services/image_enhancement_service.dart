import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/services/bulk_processing/cancel_token.dart';
import '../../../shared/services/bulk_processing/worker_pool.dart';
import '../../../shared/services/enhancement_cache_service.dart';
import '../../../shared/services/temp_file_service.dart';
import '../models/scan_enhance_kind.dart';
import 'image_enhancement_isolate.dart';

final imageEnhancementServiceProvider =
    Provider<ImageEnhancementService>((ref) => ImageEnhancementService(ref));

class ScanEnhancementPreset {
  const ScanEnhancementPreset({
    required this.label,
    required this.kind,
    this.brightness = 0,
    this.contrast = 0,
  });

  final String label;
  final ScanEnhanceKind kind;
  final double brightness;
  final double contrast;

  static const auto = ScanEnhancementPreset(
    label: 'Auto',
    kind: ScanEnhanceKind.auto,
  );

  static const magicColor = ScanEnhancementPreset(
    label: 'Magic Color',
    kind: ScanEnhanceKind.magicColor,
  );

  static const document = ScanEnhancementPreset(
    label: 'Document',
    kind: ScanEnhanceKind.document,
  );

  static const grayscale = ScanEnhancementPreset(
    label: 'Grayscale',
    kind: ScanEnhanceKind.grayscale,
  );

  static const blackAndWhite = ScanEnhancementPreset(
    label: 'B&W',
    kind: ScanEnhanceKind.blackWhite,
  );

  static const reset = ScanEnhancementPreset(
    label: 'Original',
    kind: ScanEnhanceKind.original,
  );

  static const List<ScanEnhancementPreset> all = [
    auto,
    magicColor,
    document,
    grayscale,
    blackAndWhite,
    reset,
  ];
}

class BulkEnhanceResult {
  const BulkEnhanceResult({
    required this.outputPaths,
    required this.failedPaths,
  });

  final Map<String, String> outputPaths;
  final Map<String, String> failedPaths;
}

class ImageEnhancementService {
  ImageEnhancementService(this._ref);

  final Ref _ref;

  Future<String> applyDocumentPreset(
    String sourcePath, {
    ScanEnhancementPreset preset = ScanEnhancementPreset.magicColor,
    int maxDimension = 2200,
    int jpegQuality = 88,
    bool preview = false,
  }) {
    return applyEnhancements(
      sourcePath: sourcePath,
      kind: preset.kind,
      brightness: preset.brightness,
      contrast: preset.contrast,
      maxDimension: maxDimension,
      jpegQuality: jpegQuality,
      preview: preview,
    );
  }

  Future<String> applyEnhancements({
    required String sourcePath,
    ScanEnhanceKind kind = ScanEnhanceKind.original,
    double brightness = 0,
    double contrast = 0,
    int maxDimension = 2200,
    int jpegQuality = 88,
    bool preview = false,
    bool useCache = true,
  }) async {
    if (kind == ScanEnhanceKind.original && brightness == 0 && contrast == 0) {
      return _copyOriginalOriented(sourcePath, jpegQuality: jpegQuality);
    }

    final cacheService = _ref.read(enhancementCacheServiceProvider);
    if (useCache && !preview) {
      final cached = await cacheService.lookup(
        sourcePath: sourcePath,
        kind: kind,
        brightness: brightness,
        contrast: contrast,
        maxDimension: maxDimension,
        jpegQuality: jpegQuality,
      );
      if (cached != null) return cached;
    }

    final bytes = await File(sourcePath).readAsBytes();
    if (bytes.isEmpty) {
      throw const InvalidFileException('Unable to read the scanned image.');
    }

    final outputBytes = await compute(
      enhanceImageInIsolate,
      ImageEnhanceParams(
        bytes: bytes,
        kind: kind,
        brightness: brightness,
        contrast: contrast,
        quality: jpegQuality,
        maxDimension: maxDimension,
        preview: preview,
      ),
    );

    final tempService = _ref.read(tempFileServiceProvider);
    final outputPath = await tempService.createTempFile(extension: '.jpg');
    await File(outputPath).writeAsBytes(outputBytes, flush: true);

    if (useCache && !preview) {
      return cacheService.store(
        sourcePath: sourcePath,
        kind: kind,
        brightness: brightness,
        contrast: contrast,
        maxDimension: maxDimension,
        jpegQuality: jpegQuality,
        bytes: outputBytes,
      );
    }

    return outputPath;
  }

  Future<BulkEnhanceResult> enhanceMany({
    required List<String> sourcePaths,
    ScanEnhanceKind kind = ScanEnhanceKind.auto,
    double brightness = 0,
    double contrast = 0,
    int maxDimension = 2200,
    int jpegQuality = 88,
    CancelToken? cancelToken,
    BulkProgressCallback? onProgress,
  }) async {
    final outputPaths = <String, String>{};
    final failedPaths = <String, String>{};

    await WorkerPool.mapConcurrent<String, void>(
      items: sourcePaths,
      concurrency: WorkerPool.recommendedImageConcurrency(
        itemCount: sourcePaths.length,
      ),
      cancelToken: cancelToken,
      onProgress: onProgress,
      worker: (path, _) async {
        try {
          cancelToken?.throwIfCancelled();
          final enhanced = await applyEnhancements(
            sourcePath: path,
            kind: kind,
            brightness: brightness,
            contrast: contrast,
            maxDimension: maxDimension,
            jpegQuality: jpegQuality,
          );
          outputPaths[path] = enhanced;
        } catch (e) {
          failedPaths[path] = e.toString();
        }
      },
    );

    return BulkEnhanceResult(
      outputPaths: outputPaths,
      failedPaths: failedPaths,
    );
  }

  Future<String> _copyOriginalOriented(
    String sourcePath, {
    required int jpegQuality,
  }) async {
    final bytes = await File(sourcePath).readAsBytes();
    if (bytes.isEmpty) return sourcePath;

    final outputBytes = await compute(
      orientJpegInIsolate,
      OrientJpegParams(bytes: bytes, quality: jpegQuality),
    );

    final tempService = _ref.read(tempFileServiceProvider);
    final outputPath = await tempService.createTempFile(extension: '.jpg');
    await File(outputPath).writeAsBytes(outputBytes, flush: true);
    return outputPath;
  }
}
