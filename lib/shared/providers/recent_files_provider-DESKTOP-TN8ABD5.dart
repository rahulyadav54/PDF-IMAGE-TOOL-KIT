import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recent_file.dart';
import '../services/recent_files_service.dart';

class RecentFilesState {
  const RecentFilesState({
    required this.files,
    this.availability = const {},
  });

  final List<RecentFile> files;
  final Map<String, bool> availability;

  int get unavailableCount =>
      files.where((file) => availability[file.id] == false).length;

  bool isAvailable(RecentFile file) => availability[file.id] ?? false;
}

final recentFilesProvider =
    AsyncNotifierProvider<RecentFilesNotifier, RecentFilesState>(
  RecentFilesNotifier.new,
);

class RecentFilesNotifier extends AsyncNotifier<RecentFilesState> {
  @override
  Future<RecentFilesState> build() async => _loadState();

  Future<RecentFilesState> _loadState() async {
    final service = ref.read(recentFilesServiceProvider);
    final files = await service.loadAll();
    final availability = await service.checkAvailability(files);
    return RecentFilesState(files: files, availability: availability);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadState);
  }

  Future<void> addEntry(RecentFile file) async {
    final service = ref.read(recentFilesServiceProvider);
    await service.add(file);
    await refresh();
  }

  Future<void> remove(String id) async {
    final service = ref.read(recentFilesServiceProvider);
    await service.remove(id);
    await refresh();
  }

  Future<void> clearAll() async {
    final service = ref.read(recentFilesServiceProvider);
    await service.clearAll();
    await refresh();
  }

  Future<int> removeUnavailable() async {
    final service = ref.read(recentFilesServiceProvider);
    final removed = await service.removeUnavailable();
    await refresh();
    return removed;
  }
}
