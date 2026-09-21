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

  static const color = ScanEnhancementPreset(
    label: 'Color',
    kind: ScanEnhanceKind.magicColor,
  );

  static const magicColor = color;

  static const document = ScanEnhancementPreset(
    label: 'Document',
    kind: ScanEnhanceKind.document,
  );

  static const gray = ScanEnhancementPreset(
    label: 'Gray',
    kind: ScanEnhanceKind.grayscale,
  );

  static const grayscale = gray;

  static const blackAndWhite = ScanEnhancementPreset(
    label: 'B&W',
    kind: ScanEnhanceKind.blackWhite,
  );

  static const original = ScanEnhancementPreset(
    label: 'Original',
    kind: ScanEnhanceKind.original,
  );

  static const reset = original;

  static const List<ScanEnhancementPreset> scanModes = [
    auto,
    original,
    color,
    gray,
    blackAndWhite,
  ];

  static const List<ScanEnhancementPreset> all = scanModes;
}

class ApplyEnhanceResult {
  const ApplyEnhanceResult({
    required this.path,
    required this.applied,
  });

  final String path;
  final bool applied;
}

class BulkEnhanceResult {
  const BulkEnhanceResult({
    required this.outputPaths,
    required this.failedPaths,
    required this.revertedPaths,
    required this.appliedPaths,
  });

  final Map<String, String> outputPaths;
  final Map<String, String> failedPaths;
  final Map<String, String> revertedPaths;
  final Map<String, bool> appliedPaths;

  int get appliedCount =>
      appliedPaths.values.where((applied) => applied).length;

  int get revertedCount => revertedPaths.length;
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
  }) async {
    final result = await applyEnhancements(
      sourcePath: sourcePath,
      kind: preset.kind,
      brightness: preset.brightness,
      contrast: preset.contrast,
      maxDimension: maxDimension,
      jpegQuality: jpegQuality,
      preview: preview,
    );
    return result.path;
  }

  Future<ApplyEnhanceResult> applyEnhancements({
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
      final path = await _copyOriginalOriented(
        sourcePath,
        jpegQuality: jpegQuality,
      );
      return ApplyEnhanceResult(path: path, applied: false);
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
      if (cached != null) {
        return ApplyEnhanceResult(path: cached, applied: true);
      }
    }

    final bytes = await File(sourcePath).readAsBytes();
    if (bytes.isEmpty) {
      throw const InvalidFileException('Unable to read the scanned image.');
    }

    final isolateResult = await compute(
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
    await File(outputPath).writeAsBytes(isolateResult.bytes, flush: true);

    if (useCache && !preview && isolateResult.applied) {
      final cachedPath = await cacheService.store(
        sourcePath: sourcePath,
        kind: kind,
        brightness: brightness,
        contrast: contrast,
        maxDimension: maxDimension,
        jpegQuality: jpegQuality,
        bytes: isolateResult.bytes,
      );
      return ApplyEnhanceResult(path: cachedPath, applied: true);
    }

    return ApplyEnhanceResult(
      path: outputPath,
      applied: isolateResult.applied,
    );
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
    final revertedPaths = <String, String>{};
    final appliedPaths = <String, bool>{};

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
          final result = await applyEnhancements(
            sourcePath: path,
            kind: kind,
            brightness: brightness,
            contrast: contrast,
            maxDimension: maxDimension,
            jpegQuality: jpegQuality,
          );
          outputPaths[path] = result.path;
          appliedPaths[path] = result.applied;
          if (!result.applied) {
            revertedPaths[path] =
                'Enhancement did not improve this page — try better lighting or retake.';
          }
        } catch (e) {
          failedPaths[path] = e.toString();
        }
      },
    );

    return BulkEnhanceResult(
      outputPaths: outputPaths,
      failedPaths: failedPaths,
      revertedPaths: revertedPaths,
      appliedPaths: appliedPaths,
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
