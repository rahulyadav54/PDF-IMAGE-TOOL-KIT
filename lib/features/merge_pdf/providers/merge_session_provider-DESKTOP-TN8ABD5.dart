import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/merge_pdf_item.dart';

final mergeSessionProvider =
    StateNotifierProvider.autoDispose<MergeSessionNotifier, List<MergePdfItem>>(
  (ref) => MergeSessionNotifier(),
);

class MergeSessionNotifier extends StateNotifier<List<MergePdfItem>> {
  MergeSessionNotifier() : super(const []);

  void setItems(List<MergePdfItem> items) => state = items;

  void addItems(List<MergePdfItem> items) {
    final existingPaths = state.map((e) => e.filePath).toSet();
    final newItems = items.where((i) => !existingPaths.contains(i.filePath));
    state = [...state, ...newItems];
  }

  void remove(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void reorder(int oldIndex, int newIndex) {
    final items = [...state];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = items;
  }

  void clear() => state = const [];

  int get totalPages => state.fold(0, (sum, item) => sum + item.pageCount);

  int get totalBytes => state.fold(0, (sum, item) => sum + item.fileSizeBytes);
}
