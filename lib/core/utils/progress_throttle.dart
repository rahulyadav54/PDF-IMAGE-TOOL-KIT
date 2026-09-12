import 'dart:async';

/// Throttles high-frequency progress callbacks to reduce UI rebuilds.
class ProgressThrottle {
  ProgressThrottle({this.intervalMs = 120});

  final int intervalMs;
  DateTime? _lastEmit;
  Timer? _pendingTimer;
  void Function()? _pendingCallback;

  void call(void Function() emit) {
    final now = DateTime.now();
    final last = _lastEmit;
    if (last == null || now.difference(last).inMilliseconds >= intervalMs) {
      _lastEmit = now;
      emit();
      return;
    }

    _pendingCallback = emit;
    _pendingTimer?.cancel();
    _pendingTimer = Timer(Duration(milliseconds: intervalMs), () {
      _lastEmit = DateTime.now();
      _pendingCallback?.call();
      _pendingCallback = null;
    });
  }

  void dispose() {
    _pendingTimer?.cancel();
    _pendingTimer = null;
    _pendingCallback = null;
  }

  void flush(void Function() emit) {
    _pendingTimer?.cancel();
    _pendingCallback = null;
    _lastEmit = DateTime.now();
    emit();
  }
}
