import 'package:flutter/foundation.dart';

/// Catches uncaught framework/async errors so the app does not hard-crash.
class ErrorHandling {
  ErrorHandling._();

  static void install() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Uncaught async error: $error\n$stack');
      return true;
    };
  }
}
