import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

final fileOrganizationProvider =
    StateNotifierProvider<FileOrganizationNotifier, FileOrganizationState>(
  (ref) => FileOrganizationNotifier(),
);

class FileOrganizationState {
  const FileOrganizationState({
    this.tagsByPath = const {},
    this.foldersByPath = const {},
    this.folders = const ['Work', 'Personal'],
  });

  final Map<String, List<String>> tagsByPath;
  final Map<String, String> foldersByPath;
  final List<String> folders;

  FileOrganizationState copyWith({
    Map<String, List<String>>? tagsByPath,
    Map<String, String>? foldersByPath,
    List<String>? folders,
  }) =>
      FileOrganizationState(
        tagsByPath: tagsByPath ?? this.tagsByPath,
        foldersByPath: foldersByPath ?? this.foldersByPath,
        folders: folders ?? this.folders,
      );
}

class FileOrganizationNotifier extends StateNotifier<FileOrganizationState> {
  FileOrganizationNotifier() : super(const FileOrganizationState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final tagsRaw = prefs.getString(AppConstants.fileTagsKey);
    final foldersRaw = prefs.getString(AppConstants.fileFoldersKey);
    final folderListRaw = prefs.getStringList('folder_names');

    state = FileOrganizationState(
      tagsByPath: tagsRaw != null
          ? Map<String, List<String>>.from(
              (jsonDecode(tagsRaw) as Map<String, dynamic>).map(
                (k, v) => MapEntry(k, List<String>.from(v as List)),
              ),
            )
          : {},
      foldersByPath: foldersRaw != null
          ? Map<String, String>.from(jsonDecode(foldersRaw) as Map)
          : {},
      folders: folderListRaw ?? const ['Work', 'Personal'],
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.fileTagsKey,
      jsonEncode(state.tagsByPath),
    );
    await prefs.setString(
      AppConstants.fileFoldersKey,
      jsonEncode(state.foldersByPath),
    );
    await prefs.setStringList('folder_names', state.folders);
  }

  Future<void> setFolder(String filePath, String? folder) async {
    final foldersByPath = Map<String, String>.from(state.foldersByPath);
    if (folder == null || folder.isEmpty) {
      foldersByPath.remove(filePath);
    } else {
      foldersByPath[filePath] = folder;
    }
    state = state.copyWith(foldersByPath: foldersByPath);
    await _persist();
  }

  Future<void> toggleTag(String filePath, String tag) async {
    final tagsByPath = Map<String, List<String>>.from(state.tagsByPath);
    final tags = List<String>.from(tagsByPath[filePath] ?? []);
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    tagsByPath[filePath] = tags;
    state = state.copyWith(tagsByPath: tagsByPath);
    await _persist();
  }

  Future<void> addFolder(String name) async {
    if (state.folders.contains(name)) return;
    state = state.copyWith(folders: [...state.folders, name]);
    await _persist();
  }
}
