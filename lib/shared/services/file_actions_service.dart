import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/path_security.dart';

final fileActionsServiceProvider =
    Provider<FileActionsService>((ref) => FileActionsService());

class FileSaveResult {
  const FileSaveResult({required this.savedPath, required this.message});

  final String savedPath;
  final String message;
}

/// Share, open, gallery save, and download actions for output files.
class FileActionsService {
  static const _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'bmp',
    'gif',
    'heic',
    'heif',
  };

  bool isImage(String path) => _imageExtensions.contains(_extension(path));

  bool isPdf(String path) => _extension(path) == 'pdf';

  bool isZip(String path) => _extension(path) == 'zip';

  Future<void> shareFile(String path, {String? subject}) async {
    await _validatePath(path);
    await Share.shareXFiles([XFile(path)], subject: subject);
  }

  /// Opens a file in the system default app (external viewer).
  Future<void> openFileExternally(String path) async {
    await _validatePath(path);
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      throw const ProcessingException(
        'Unable to open this file on your device.',
      );
    }
  }

  /// @deprecated Use [FileOpener.open] from UI code for in-app PDF viewing.
  Future<void> openFile(String path) => openFileExternally(path);

  /// Saves an image to the device photo gallery (Photos app).
  Future<FileSaveResult> saveImageToGallery(String path) async {
    await _validatePath(path);
    if (!isImage(path)) {
      throw const ProcessingException('Only images can be saved to the gallery.');
    }

    final hasAccess = await Gal.hasAccess(toAlbum: true);
    if (!hasAccess) {
      final granted = await Gal.requestAccess(toAlbum: true);
      if (!granted) {
        throw const PermissionDeniedException('Photos');
      }
    }

    await Gal.putImage(path);
    return FileSaveResult(
      savedPath: path,
      message: 'Image saved to your gallery.',
    );
  }

  /// Copies a file to the public Downloads/PDF Image Toolbox folder.
  Future<FileSaveResult> saveToDownloads(String path) async {
    await _validatePath(path);

    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir == null) {
      throw const StorageException('Downloads folder is not available on this device.');
    }

    final outputFolder = Directory(p.join(downloadsDir.path, 'PDF Image Toolbox'));
    if (!await outputFolder.exists()) {
      await outputFolder.create(recursive: true);
    }

    final fileName = p.basename(path);
    var destinationPath = p.join(outputFolder.path, fileName);

    if (await File(destinationPath).exists()) {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      destinationPath = p.join(
        outputFolder.path,
        '${p.basenameWithoutExtension(fileName)}_$stamp${p.extension(fileName)}',
      );
    }

    await File(path).copy(destinationPath);

    final label = isPdf(path)
        ? 'PDF'
        : isImage(path)
            ? 'Image'
            : isZip(path)
                ? 'ZIP file'
                : 'File';

    return FileSaveResult(
      savedPath: destinationPath,
      message: '$label saved to Downloads/PDF Image Toolbox',
    );
  }

  Future<void> _validatePath(String path) async {
    try {
      await PathSecurity.assertSafeReadableFile(path);
    } on FormatException {
      throw const InvalidFileException('File no longer exists.');
    }
  }

  String _extension(String path) {
    final ext = p.extension(path).toLowerCase();
    if (ext.isEmpty) return '';
    return ext.substring(1);
  }
}
