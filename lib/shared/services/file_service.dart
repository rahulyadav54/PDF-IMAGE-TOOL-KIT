import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/path_security.dart';

final fileServiceProvider = Provider<FileService>((ref) => FileService());

/// Handles file picking, validation, and output directory access.
class FileService {
  Future<String?> pickFile({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    final fileType = allowedExtensions != null ? FileType.custom : type;
    final result = await FilePicker.platform.pickFiles(
      type: fileType,
      allowedExtensions: allowedExtensions,
      allowMultiple: false,
      withData: false,
      withReadStream: true,
    );

    if (result == null || result.files.isEmpty) {
      throw const FilePickerCancelledException();
    }

    final path = result.files.single.path;
    if (path == null || path.isEmpty) {
      throw const InvalidFileException();
    }
    return path;
  }

  Future<List<String>> pickMultipleFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    final fileType = allowedExtensions != null ? FileType.custom : type;
    final result = await FilePicker.platform.pickFiles(
      type: fileType,
      allowedExtensions: allowedExtensions,
      allowMultiple: true,
      withData: false,
      withReadStream: true,
    );

    if (result == null || result.files.isEmpty) {
      throw const FilePickerCancelledException();
    }

    final paths = result.files
        .map((f) => f.path)
        .whereType<String>()
        .where((p) => p.isNotEmpty)
        .toList();

    if (paths.isEmpty) {
      throw const InvalidFileException();
    }
    return paths;
  }

  Future<int> getFileSize(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const InvalidFileException('File no longer exists.');
    }
    return file.length();
  }

  Future<bool> fileExists(String path) => File(path).exists();

  Future<String> getOutputDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final output = Directory('${dir.path}/PDF Image Toolbox');
    if (!await output.exists()) {
      await output.create(recursive: true);
    }
    return output.path;
  }

  Future<String> saveToOutput(String fileName, List<int> bytes) async {
    final outputDir = await getOutputDirectory();
    try {
      final outputPath = PathSecurity.outputPath(outputDir, fileName);
      final file = File(outputPath);
      await file.writeAsBytes(bytes, flush: true);
      return outputPath;
    } on FormatException {
      throw const StorageException('Invalid output filename.');
    }
  }

  String getFileName(String path) => File(path).uri.pathSegments.last;

  String getExtension(String path) {
    final name = getFileName(path);
    final dot = name.lastIndexOf('.');
    return dot >= 0 ? name.substring(dot + 1).toLowerCase() : '';
  }

  bool isPdf(String path) => getExtension(path) == 'pdf';

  bool isImage(String path) {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif', 'heic', 'heif'];
    return imageExtensions.contains(getExtension(path));
  }

  Future<String> getIncomingDirectory() async {
    final outputDir = await getOutputDirectory();
    final incoming = Directory(p.join(outputDir, 'Incoming'));
    if (!await incoming.exists()) {
      await incoming.create(recursive: true);
    }
    return incoming.path;
  }

  /// Copies a shared/opened file into durable app storage under Incoming/.
  Future<String> importIncomingFile({
    required String sourcePath,
    String? suggestedName,
  }) async {
    final incomingDir = await getIncomingDirectory();
    final baseName = suggestedName?.trim().isNotEmpty == true
        ? suggestedName!.trim()
        : getFileName(sourcePath);

    String safeName;
    try {
      safeName = PathSecurity.sanitizeFileName(baseName);
    } on FormatException {
      safeName = PathSecurity.sanitizeFileName('shared_file');
    }

    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const InvalidFileException('Could not read the shared file.');
    }

    final size = await source.length();
    if (size > AppConstants.maxIncomingFileBytes) {
      throw const InvalidFileException('File is too large (max 150 MB).');
    }

    var outputPath = PathSecurity.outputPath(incomingDir, safeName);
    if (await File(outputPath).exists()) {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final ext = p.extension(safeName);
      final stem = p.basenameWithoutExtension(safeName);
      final stampedName = ext.isEmpty ? '${stem}_$stamp' : '${stem}_$stamp$ext';
      outputPath = PathSecurity.outputPath(incomingDir, stampedName);
    }

    await source.copy(outputPath);
    return outputPath;
  }
}
