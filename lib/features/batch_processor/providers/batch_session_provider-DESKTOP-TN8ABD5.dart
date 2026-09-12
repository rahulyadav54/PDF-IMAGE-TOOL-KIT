import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/batch_file_item.dart';
import '../models/batch_operation_type.dart';

class BatchSessionState {
  const BatchSessionState({
    this.operationType = BatchOperationType.imageConvert,
    this.files = const [],
    this.config = const BatchConfig(),
  });

  final BatchOperationType operationType;
  final List<BatchFileItem> files;
  final BatchConfig config;

  BatchSessionState copyWith({
    BatchOperationType? operationType,
    List<BatchFileItem>? files,
    BatchConfig? config,
  }) {
    return BatchSessionState(
      operationType: operationType ?? this.operationType,
      files: files ?? this.files,
      config: config ?? this.config,
    );
  }
}

class BatchSessionNotifier extends StateNotifier<BatchSessionState> {
  BatchSessionNotifier() : super(const BatchSessionState());

  void setOperation(BatchOperationType type) {
    state = BatchSessionState(
      operationType: type,
      files: const [],
      config: state.config,
    );
  }

  void setConfig(BatchConfig config) {
    state = state.copyWith(config: config);
  }

  void addFiles(List<BatchFileItem> items) {
    final existing = state.files.map((f) => f.filePath).toSet();
    final merged = [
      ...state.files,
      ...items.where((item) => !existing.contains(item.filePath)),
    ];
    state = state.copyWith(files: merged);
  }

  void removeFile(String id) {
    state = state.copyWith(
      files: state.files.where((f) => f.id != id).toList(),
    );
  }

  void clear() {
    state = const BatchSessionState();
  }
}

final batchSessionProvider =
    StateNotifierProvider<BatchSessionNotifier, BatchSessionState>(
  (ref) => BatchSessionNotifier(),
);
