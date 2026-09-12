/// Unified processing job model for bulk and long-running operations.
enum ProcessingStatus {
  queued,
  processing,
  paused,
  completed,
  failed,
  cancelled,
}

class ProcessingJob {
  ProcessingJob({
    required this.id,
    required this.title,
    required this.type,
    required this.totalItems,
    this.completedItems = 0,
    this.failedItems = 0,
    this.currentItem = 0,
    this.currentLabel,
    this.status = ProcessingStatus.queued,
    this.errorMessage,
    this.failedLabels = const [],
  });

  final String id;
  final String title;
  final String type;
  final int totalItems;
  final int completedItems;
  final int failedItems;
  final int currentItem;
  final String? currentLabel;
  final ProcessingStatus status;
  final String? errorMessage;
  final List<String> failedLabels;

  int get remainingItems =>
      (totalItems - completedItems - failedItems).clamp(0, totalItems);

  double? get progress =>
      totalItems > 0 ? completedItems / totalItems : null;

  String get progressLabel => '$completedItems / $totalItems';

  bool get isActive =>
      status == ProcessingStatus.processing ||
      status == ProcessingStatus.queued;

  ProcessingJob copyWith({
    int? totalItems,
    int? completedItems,
    int? failedItems,
    int? currentItem,
    String? currentLabel,
    ProcessingStatus? status,
    String? errorMessage,
    List<String>? failedLabels,
  }) {
    return ProcessingJob(
      id: id,
      title: title,
      type: type,
      totalItems: totalItems ?? this.totalItems,
      completedItems: completedItems ?? this.completedItems,
      failedItems: failedItems ?? this.failedItems,
      currentItem: currentItem ?? this.currentItem,
      currentLabel: currentLabel ?? this.currentLabel,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      failedLabels: failedLabels ?? this.failedLabels,
    );
  }
}
