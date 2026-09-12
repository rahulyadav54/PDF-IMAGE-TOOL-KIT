import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

final tempFileServiceProvider =
    Provider<TempFileService>((ref) => TempFileService());

/// Manages temporary files with safe cleanup.
class TempFileService {
  final _uuid = const Uuid();
  final Set<String> _trackedPaths = {};

  Future<String> createTempFile({String extension = '.tmp'}) async {
    final dir = await getTemporaryDirectory();
    final appTemp = Directory('${dir.path}/pdf_image_toolbox_temp');
    if (!await appTemp.exists()) {
      await appTemp.create(recursive: true);
    }
    final path = '${appTemp.path}/${_uuid.v4()}$extension';
    _trackedPaths.add(path);
    return path;
  }

  Future<Directory> createTempDirectory() async {
    final dir = await getTemporaryDirectory();
    final appTemp = Directory('${dir.path}/pdf_image_toolbox_temp/${_uuid.v4()}');
    await appTemp.create(recursive: true);
    _trackedPaths.add(appTemp.path);
    return appTemp;
  }

  Future<void> delete(String path) async {
    final entity = FileSystemEntity.typeSync(path);
    if (entity == FileSystemEntityType.file) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } else if (entity == FileSystemEntityType.directory) {
      final dir = Directory(path);
      if (await dir.exists()) await dir.delete(recursive: true);
    }
    _trackedPaths.remove(path);
  }

  bool isManagedTempPath(String path) =>
      path.contains('pdf_image_toolbox_temp');

  Future<void> cleanupAll() async {
    for (final path in _trackedPaths.toList()) {
      await delete(path);
    }
    final dir = await getTemporaryDirectory();
    final appTemp = Directory('${dir.path}/pdf_image_toolbox_temp');
    if (await appTemp.exists()) {
      await appTemp.delete(recursive: true);
    }
  }
}
