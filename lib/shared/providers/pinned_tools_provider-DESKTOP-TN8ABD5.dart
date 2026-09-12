import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/tool_catalog.dart';


final pinnedToolRoutesProvider =
    StateNotifierProvider<PinnedToolRoutesNotifier, List<String>>(
  (ref) => PinnedToolRoutesNotifier(),
);

class PinnedToolRoutesNotifier extends StateNotifier<List<String>> {
  PinnedToolRoutesNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.pinnedToolsKey);
    if (raw == null || raw.isEmpty) {
      state = _defaultRoutes;
      return;
    }
    try {
      final list = (jsonDecode(raw) as List<dynamic>).map((e) => e.toString()).toList();
      state = list.isEmpty ? _defaultRoutes : list;
    } catch (_) {
      state = _defaultRoutes;
    }
  }

  static const _defaultRoutes = [
    '/scan-to-pdf',
    '/image-to-pdf',
    '/compress-pdf',
  ];

  Future<void> toggle(String route) async {
    final next = List<String>.from(state);
    if (next.contains(route)) {
      next.remove(route);
    } else {
      next.insert(0, route);
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.pinnedToolsKey, jsonEncode(next));
  }

  bool isPinned(String route) => state.contains(route);

  List<ToolCatalogEntry> pinnedEntries() {
    final all = ToolCatalog.searchable;
    return state
        .map((route) => all.where((e) => e.route == route).firstOrNull)
        .whereType<ToolCatalogEntry>()
        .toList();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
