import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/services/bulk_processing/cancel_token.dart';
import '../../../shared/services/temp_file_service.dart';
import '../models/scan_page.dart';
import '../services/image_enhancement_service.dart';

final scanSessionProvider =
    StateNotifierProvider.autoDispose<ScanSessionNotifier, List<ScanPage>>(
  ScanSessionNotifier.new,
);

typedef ScanEnhanceProgress = void Function(int completed, int total);

class ScanSessionNotifier extends StateNotifier<List<ScanPage>> {
  ScanSessionNotifier(this._ref) : super(const []);

  final Ref _ref;
  static const _uuid = Uuid();

  void addPage(String imagePath) {
    addPages([imagePath]);
  }

  void addPages(List<String> imagePaths) {
    if (imagePaths.isEmpty) return;

    final newPages = imagePaths.map((path) {
      return ScanPage(
        id: _uuid.v4(),
        originalImagePath: path,
        displayImagePath: path,
      );
    }).toList();

    state = [...state, ...newPages];
  }

  Future<void> enhanceAllPages({
    ScanEnhancementPreset preset = ScanEnhancementPreset.magicColor,
    CancelToken? cancelToken,
    ScanEnhanceProgress? onProgress,
  }) async {
    if (state.isEmpty) return;

    final service = _ref.read(imageEnhancementServiceProvider);
    final result = await service.enhanceMany(
      sourcePaths: state.map((p) => p.originalImagePath).toList(),
      kind: preset.kind,
      brightness: preset.brightness,
      contrast: preset.contrast,
      cancelToken: cancelToken,
      onProgress: onProgress,
    );

    final updatedPages = <ScanPage>[];
    for (final page in state) {
      final enhancedPath = result.outputPaths[page.originalImagePath];
      if (enhancedPath == null) {
        updatedPages.add(page);
        continue;
      }

      await _deleteDisplayPathIfNeeded(page, enhancedPath);
      updatedPages.add(
        page.copyWith(
          displayImagePath: enhancedPath,
          enhanceKind: preset.kind,
          brightness: preset.brightness,
          contrast: preset.contrast,
        ),
      );
    }

    state = updatedPages;
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

  Future<void> _deleteDisplayPathIfNeeded(ScanPage page, String nextPath) async {
    final previous = page.displayImagePath;
    if (previous == nextPath || previous == page.originalImagePath) return;

    final tempService = _ref.read(tempFileServiceProvider);
    if (tempService.isManagedTempPath(previous) && await File(previous).exists()) {
      await tempService.delete(previous);
    }
  }

  Future<void> _deletePageFiles(ScanPage page) async {
    final tempService = _ref.read(tempFileServiceProvider);
    final paths = {page.originalImagePath, page.displayImagePath};

    for (final path in paths) {
      if (tempService.isManagedTempPath(path) && await File(path).exists()) {
        await tempService.delete(path);
      }
    }
  }
}
