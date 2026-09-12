import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/errors/app_exception.dart';

final storageGuardServiceProvider =
    Provider<StorageGuardService>((ref) => const StorageGuardService());

class StorageGuardService {
  const StorageGuardService();

  /// Estimates bytes needed for processing (input × multiplier + overhead).
  Future<int> estimateRequiredBytes(
    List<String> paths, {
    double multiplier = 2.5,
    int overheadBytes = 32 * 1024 * 1024,
  }) async {
    var inputBytes = 0;
    for (final path in paths) {
      final file = File(path);
      if (await file.exists()) {
        inputBytes += await file.length();
      }
    }
    return (inputBytes * multiplier).round() + overheadBytes;
  }

  /// Verifies there is likely enough free space before a large job.
  Future<void> ensureSpaceForPaths(
    List<String> paths, {
    double multiplier = 2.5,
  }) async {
    final required = await estimateRequiredBytes(paths, multiplier: multiplier);
    await ensureSpace(required);
  }

  Future<void> ensureSpace(int requiredBytes) async {
    if (requiredBytes <= 0) return;

    final tempDir = await getTemporaryDirectory();
    final probeSize = requiredBytes.clamp(512 * 1024, 16 * 1024 * 1024);
    final probe = File('${tempDir.path}/.storage_probe');

    try {
      await probe.writeAsBytes(
        List.filled(probeSize, 0),
        flush: true,
      );
      await probe.delete();
    } catch (_) {
      throw const StorageException('Not enough storage space.');
    }
  }
}
