import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/scan_to_pdf/models/scan_enhance_kind.dart';

final enhancementCacheServiceProvider =
    Provider<EnhancementCacheService>((ref) => EnhancementCacheService());

/// Disk cache for enhanced images keyed by source identity + settings.
class EnhancementCacheService {
  Directory? _cacheDir;

  Future<Directory> _directory() async {
    if (_cacheDir != null) return _cacheDir!;
    final base = await getTemporaryDirectory();
    _cacheDir = Directory(p.join(base.path, 'enhancement_cache'));
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  Future<String?> lookup({
    required String sourcePath,
    required ScanEnhanceKind kind,
    required double brightness,
    required double contrast,
    required int maxDimension,
    required int jpegQuality,
  }) async {
    final key = await _cacheKey(
      sourcePath: sourcePath,
      kind: kind,
      brightness: brightness,
      contrast: contrast,
      maxDimension: maxDimension,
      jpegQuality: jpegQuality,
    );
    final file = File(p.join((await _directory()).path, '$key.jpg'));
    if (await file.exists()) return file.path;
    return null;
  }

  Future<String> store({
    required String sourcePath,
    required ScanEnhanceKind kind,
    required double brightness,
    required double contrast,
    required int maxDimension,
    required int jpegQuality,
    required List<int> bytes,
  }) async {
    final key = await _cacheKey(
      sourcePath: sourcePath,
      kind: kind,
      brightness: brightness,
      contrast: contrast,
      maxDimension: maxDimension,
      jpegQuality: jpegQuality,
    );
    final file = File(p.join((await _directory()).path, '$key.jpg'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> clear() async {
    final dir = await _directory();
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        await entity.delete(recursive: true);
      }
    }
  }

  /// Removes oldest cache files when total size exceeds [maxTotalBytes].
  Future<void> prune({required int maxTotalBytes}) async {
    final dir = await _directory();
    if (!await dir.exists()) return;

    final files = <File>[];
    var total = 0;
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final stat = await entity.stat();
      files.add(entity);
      total += stat.size;
    }

    if (total <= maxTotalBytes) return;

    files.sort(
      (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
    );

    for (final file in files) {
      if (total <= maxTotalBytes) break;
      final size = await file.length();
      await file.delete();
      total -= size;
    }
  }

  Future<String> _cacheKey({
    required String sourcePath,
    required ScanEnhanceKind kind,
    required double brightness,
    required double contrast,
    required int maxDimension,
    required int jpegQuality,
  }) async {
    final file = File(sourcePath);
    final stat = await file.stat();
    final payload = jsonEncode({
      'path': p.normalize(sourcePath),
      'modified': stat.modified.millisecondsSinceEpoch,
      'size': stat.size,
      'kind': kind.name,
      'brightness': brightness,
      'contrast': contrast,
      'maxDimension': maxDimension,
      'jpegQuality': jpegQuality,
    });
    return sha256.convert(utf8.encode(payload)).toString();
  }
}
