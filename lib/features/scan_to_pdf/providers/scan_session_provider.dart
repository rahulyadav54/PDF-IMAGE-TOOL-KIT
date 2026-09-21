import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/services/bulk_processing/cancel_token.dart';
import '../../../shared/services/document_processing/document_boundary_detector.dart';
import '../../../shared/services/temp_file_service.dart';
import '../models/scan_capture_source.dart';
import '../models/scan_enhance_kind.dart';
import '../models/scan_page.dart';
import '../services/document_geometry_service.dart';
import '../services/image_enhancement_service.dart';

final scanSessionProvider =
    StateNotifierProvider.autoDispose<ScanSessionNotifier, List<ScanPage>>(
  ScanSessionNotifier.new,
);

typedef ScanEnhanceProgress = void Function(int completed, int total);
typedef ScanGeometryProgress = void Function(
  int completed,
  int total,
  String message,
);

class ProcessPagesResult {
  const ProcessPagesResult({
    required this.pages,
    required this.needsManualCornerPages,
  });

  final List<ScanPage> pages;
  final List<ScanPage> needsManualCornerPages;
}

class EnhanceAllPagesResult {
  const EnhanceAllPagesResult({
    required this.appliedCount,
    required this.revertedCount,
    required this.failedCount,
  });

  final int appliedCount;
  final int revertedCount;
  final int failedCount;

  bool get anyApplied => appliedCount > 0;
  bool get anyFailed => failedCount > 0 || revertedCount > 0;
}

class ScanSessionNotifier extends StateNotifier<List<ScanPage>> {
  ScanSessionNotifier(this._ref) : super(const []);

  final Ref _ref;
  static const _uuid = Uuid();

  /// Adds pre-processed page paths without running geometry (tests / internal).
  void addPages(List<String> imagePaths) {
    if (imagePaths.isEmpty) return;

    final newPages = imagePaths.map((path) {
      return ScanPage(
        id: _uuid.v4(),
        rawCapturePath: path,
        originalImagePath: path,
        displayImagePath: path,
        geometryApplied: true,
      );
    }).toList();

    state = [...state, ...newPages];
  }

  void addPage(String imagePath) => addPages([imagePath]);

  Future<ProcessPagesResult> addAndProcessPages(
    List<String> rawPaths, {
    ScanCaptureSource source = ScanCaptureSource.gallery,
    ScanGeometryProgress? onProgress,
  }) async {
    if (rawPaths.isEmpty) {
      return const ProcessPagesResult(pages: [], needsManualCornerPages: []);
    }

    final geometryService = _ref.read(documentGeometryServiceProvider);
    final newPages = <ScanPage>[];
    final needsManual = <ScanPage>[];

    for (var i = 0; i < rawPaths.length; i++) {
      final isScanner = source == ScanCaptureSource.nativeScanner;
      onProgress?.call(
        i,
        rawPaths.length,
        isScanner ? 'Preparing scan...' : 'Detecting document...',
      );
      final geo = await geometryService.processCapture(
        rawPaths[i],
        source: source,
      );

      onProgress?.call(
        i,
        rawPaths.length,
        isScanner ? 'Preparing scan...' : 'Correcting perspective...',
      );

      final page = ScanPage(
        id: _uuid.v4(),
        rawCapturePath: rawPaths[i],
        originalImagePath: geo.geometryPath,
        displayImagePath: geo.geometryPath,
        geometryApplied: geo.geometryApplied,
        geometryConfidence: geo.confidence,
        needsCornerAdjustment: geo.needsManualAdjustment,
        corners: geo.corners,
        enhanceKind: ScanEnhanceKind.auto,
      );

      newPages.add(page);
      if (geo.needsManualAdjustment &&
          source != ScanCaptureSource.nativeScanner) {
        needsManual.add(page);
      }
    }

    state = [...state, ...newPages];
    return ProcessPagesResult(
      pages: newPages,
      needsManualCornerPages: needsManual,
    );
  }

  Future<ScanPage> reapplyGeometry(
    ScanPage page,
    List<DocumentCorner> corners,
  ) async {
    final geometryService = _ref.read(documentGeometryServiceProvider);
    final geo = await geometryService.processCapture(
      page.rawCapturePath,
      manualCorners: corners,
    );

    await _deleteGeometryPathIfNeeded(page, geo.geometryPath);
    await _deleteDisplayPathIfNeeded(page, geo.geometryPath);

    final updated = page.copyWith(
      originalImagePath: geo.geometryPath,
      displayImagePath: geo.geometryPath,
      geometryApplied: geo.geometryApplied,
      geometryConfidence: geo.confidence,
      needsCornerAdjustment: false,
      corners: geo.corners,
      enhanceKind: ScanEnhanceKind.auto,
      brightness: 0,
      contrast: 0,
    );

    state = state.map((p) => p.id == page.id ? updated : p).toList();
    return updated;
  }

  Future<EnhanceAllPagesResult> enhanceAllPages({
    ScanEnhancementPreset preset = ScanEnhancementPreset.auto,
    CancelToken? cancelToken,
    ScanEnhanceProgress? onProgress,
    List<String>? pageIds,
  }) async {
    final targets = pageIds == null
        ? state
        : state.where((p) => pageIds.contains(p.id)).toList();

    if (targets.isEmpty) {
      return const EnhanceAllPagesResult(
        appliedCount: 0,
        revertedCount: 0,
        failedCount: 0,
      );
    }

    final service = _ref.read(imageEnhancementServiceProvider);
    final result = await service.enhanceMany(
      sourcePaths: targets.map((p) => p.originalImagePath).toList(),
      kind: preset.kind,
      brightness: preset.brightness,
      contrast: preset.contrast,
      cancelToken: cancelToken,
      onProgress: onProgress,
    );

    final updatedPages = <ScanPage>[];
    for (final page in state) {
      if (!targets.any((t) => t.id == page.id)) {
        updatedPages.add(page);
        continue;
      }

      final enhancedPath = result.outputPaths[page.originalImagePath];
      if (enhancedPath == null) {
        updatedPages.add(page);
        continue;
      }

      final applied = result.appliedPaths[page.originalImagePath] ?? false;
      await _deleteDisplayPathIfNeeded(page, enhancedPath);
      updatedPages.add(
        page.copyWith(
          displayImagePath: enhancedPath,
          enhanceKind: applied ? preset.kind : page.enhanceKind,
          brightness: applied ? preset.brightness : page.brightness,
          contrast: applied ? preset.contrast : page.contrast,
        ),
      );
    }

    state = updatedPages;
    return EnhanceAllPagesResult(
      appliedCount: result.appliedCount,
      revertedCount: result.revertedCount,
      failedCount: result.failedPaths.length,
    );
  }

  Future<void> removePage(String id) async {
    final page = state.where((p) => p.id == id).firstOrNull;
    if (page != null) await _deletePageFiles(page);
    state = state.where((p) => p.id != id).toList();
  }

  Future<void> removeLastPages(int count) async {
    if (count <= 0 || state.isEmpty) return;
    final removeCount = count.clamp(1, state.length);
    final toRemove = state.sublist(state.length - removeCount);
    for (final page in toRemove) {
      await _deletePageFiles(page);
    }
    state = state.sublist(0, state.length - removeCount);
  }

  void reorder(int oldIndex, int newIndex) {
    final pages = [...state];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = pages.removeAt(oldIndex);
    pages.insert(newIndex, item);
    state = pages;
  }

  void updatePage(ScanPage updated) {
    state = state.map((p) => p.id == updated.id ? updated : p).toList();
  }

  Future<void> clear() async {
    for (final page in state) {
      await _deletePageFiles(page);
    }
    state = const [];
  }

  Future<void> _deleteGeometryPathIfNeeded(ScanPage page, String nextPath) async {
    final previous = page.originalImagePath;
    if (previous == nextPath ||
        previous == page.rawCapturePath ||
        previous == page.displayImagePath) {
      return;
    }

    final tempService = _ref.read(tempFileServiceProvider);
    if (tempService.isManagedTempPath(previous) && await File(previous).exists()) {
      await tempService.delete(previous);
    }
  }

  Future<void> _deleteDisplayPathIfNeeded(ScanPage page, String nextPath) async {
    final previous = page.displayImagePath;
    if (previous == nextPath ||
        previous == page.originalImagePath ||
        previous == page.rawCapturePath) {
      return;
    }

    final tempService = _ref.read(tempFileServiceProvider);
    if (tempService.isManagedTempPath(previous) && await File(previous).exists()) {
      await tempService.delete(previous);
    }
  }

  Future<void> _deletePageFiles(ScanPage page) async {
    final tempService = _ref.read(tempFileServiceProvider);
    final paths = {
      page.rawCapturePath,
      page.originalImagePath,
      page.displayImagePath,
    };

    for (final path in paths) {
      if (tempService.isManagedTempPath(path) && await File(path).exists()) {
        await tempService.delete(path);
      }
    }
  }
}
