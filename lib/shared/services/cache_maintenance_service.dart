import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'enhancement_cache_service.dart';
import 'temp_file_service.dart';

final cacheMaintenanceServiceProvider =
    Provider<CacheMaintenanceService>((ref) => CacheMaintenanceService(ref));

/// Prunes temp and enhancement cache on startup and after heavy jobs.
class CacheMaintenanceService {
  CacheMaintenanceService(this._ref);

  final Ref _ref;

  static const int maxEnhancementCacheBytes = 200 * 1024 * 1024;
  static const int maxTempAgeHours = 24;

  Future<void> runMaintenance() async {
    try {
      await _pruneEnhancementCache();
      await _pruneStaleTempFiles();
    } catch (error, stack) {
      debugPrint('Cache maintenance skipped: $error\n$stack');
    }
  }

  Future<void> runAfterHeavyJob() async {
    await runMaintenance();
  }

  Future<void> _pruneEnhancementCache() async {
    await _ref.read(enhancementCacheServiceProvider).prune(
          maxTotalBytes: maxEnhancementCacheBytes,
        );
  }

  Future<void> _pruneStaleTempFiles() async {
    final tempRoot = await getTemporaryDirectory();
    final appTemp = Directory('${tempRoot.path}/pdf_image_toolbox_temp');
    if (!await appTemp.exists()) return;

    final cutoff = DateTime.now().subtract(Duration(hours: maxTempAgeHours));
    await for (final entity in appTemp.list(recursive: true)) {
      if (entity is! File) continue;
      try {
        final modified = await entity.stat();
        if (modified.modified.isBefore(cutoff)) {
          await entity.delete();
        }
      } catch (_) {
        // Ignore locked or removed files.
      }
    }
  }

  Future<void> clearAllCaches() async {
    await _ref.read(enhancementCacheServiceProvider).clear();
    await _ref.read(tempFileServiceProvider).cleanupAll();
  }
}
