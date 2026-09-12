import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _channel = MethodChannel('com.pdftoolbox/shortcuts');

final shortcutRouteProvider =
    StateNotifierProvider<ShortcutRouteNotifier, String?>(
  (ref) => ShortcutRouteNotifier(),
);

class ShortcutRouteNotifier extends StateNotifier<String?> {
  ShortcutRouteNotifier() : super(null);

  Future<void> loadInitialRoute() async {
    try {
      final route = await _channel.invokeMethod<String>('getInitialRoute');
      if (route != null && route.isNotEmpty) {
        state = route;
      }
    } catch (_) {}
  }

  void consume() => state = null;
}
