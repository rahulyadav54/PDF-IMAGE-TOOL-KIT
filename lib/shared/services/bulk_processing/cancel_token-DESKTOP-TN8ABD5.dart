/// Signals cancellation for long-running bulk jobs.
class CancelToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;

  void throwIfCancelled() {
    if (_cancelled) throw const BulkCancelledException();
  }
}

class BulkCancelledException implements Exception {
  const BulkCancelledException();

  @override
  String toString() => 'Processing was cancelled.';
}
