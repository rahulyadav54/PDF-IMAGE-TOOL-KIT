import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

final starredFilesServiceProvider = Provider<StarredFilesService>(
  (ref) => StarredFilesService(),
);

final starredPathsProvider =
    StateNotifierProvider<StarredPathsNotifier, Set<String>>(
  (ref) => StarredPathsNotifier(ref.watch(starredFilesServiceProvider)),
);

class StarredFilesService {
  Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.starredFilesKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> save(Set<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.starredFilesKey,
      jsonEncode(paths.toList()),
    );
  }
}

class StarredPathsNotifier extends StateNotifier<Set<String>> {
  StarredPathsNotifier(this._service) : super({}) {
    _load();
  }

  final StarredFilesService _service;

  Future<void> _load() async {
    state = await _service.load();
  }

  Future<void> toggle(String path) async {
    final next = Set<String>.from(state);
    if (next.contains(path)) {
      next.remove(path);
    } else {
      next.add(path);
    }
    state = next;
    await _service.save(next);
  }

  bool isStarred(String path) => state.contains(path);
}
