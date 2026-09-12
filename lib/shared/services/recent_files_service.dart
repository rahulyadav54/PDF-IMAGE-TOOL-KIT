import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../models/recent_file.dart';

final recentFilesServiceProvider =
    Provider<RecentFilesService>((ref) => RecentFilesService());

class RecentFilesService {
  final _uuid = const Uuid();

  Future<List<RecentFile>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.recentFilesKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = RecentFile.decodeList(raw);
    final sanitized = sanitize(decoded);
    if (_hasListChanged(decoded, sanitized)) {
      await _save(sanitized);
    }
    return sanitized;
  }

  Future<void> add(RecentFile file) async {
    if (file.filePath.isEmpty) return;

    final files = await loadAll();
    files.removeWhere((f) => f.filePath == file.filePath);
    files.insert(0, file);
    await _save(sanitize(files));
  }

  Future<void> remove(String id) async {
    final files = await loadAll();
    files.removeWhere((f) => f.id == id);
    await _save(files);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.recentFilesKey);
  }

  /// Removes entries whose files no longer exist on disk.
  Future<int> removeUnavailable() async {
    final files = await loadAll();
    final kept = <RecentFile>[];

    for (final file in files) {
      if (await checkExists(file)) {
        kept.add(file);
      }
    }

    final removedCount = files.length - kept.length;
    if (removedCount > 0) {
      await _save(kept);
    }
    return removedCount;
  }

  Future<bool> checkExists(RecentFile file) async {
    if (file.filePath.isEmpty) return false;
    return File(file.filePath).exists();
  }

  Future<Map<String, bool>> checkAvailability(List<RecentFile> files) async {
    final availability = <String, bool>{};
    for (final file in files) {
      availability[file.id] = await checkExists(file);
    }
    return availability;
  }

  Future<RecentFile> createEntry({
    required String filePath,
    required String operation,
    required int fileSizeBytes,
  }) async {
    final fileName = File(filePath).uri.pathSegments.last;
    final ext = fileName.contains('.') ? fileName.split('.').last : '';
    return RecentFile(
      id: _uuid.v4(),
      fileName: fileName,
      filePath: filePath,
      fileType: ext.toUpperCase(),
      operation: operation,
      processedAt: DateTime.now(),
      fileSizeBytes: fileSizeBytes,
    );
  }

  /// Deduplicates by path (newest first) and enforces the max history size.
  static List<RecentFile> sanitize(
    List<RecentFile> files, {
    int maxEntries = AppConstants.maxRecentFiles,
  }) {
    final sorted = List<RecentFile>.from(files)
      ..sort((a, b) => b.processedAt.compareTo(a.processedAt));

    final seenPaths = <String>{};
    final result = <RecentFile>[];

    for (final file in sorted) {
      if (file.filePath.isEmpty) continue;
      if (seenPaths.add(file.filePath)) {
        result.add(file);
      }
    }

    if (result.length > maxEntries) {
      return result.sublist(0, maxEntries);
    }
    return result;
  }

  Future<void> _save(List<RecentFile> files) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.recentFilesKey, RecentFile.encodeList(files));
  }

  bool _hasListChanged(List<RecentFile> original, List<RecentFile> sanitized) {
    if (original.length != sanitized.length) return true;
    for (var i = 0; i < original.length; i++) {
      if (original[i].id != sanitized[i].id) return true;
    }
    return false;
  }
}
