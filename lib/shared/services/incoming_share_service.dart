import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/incoming_file_types.dart';
import '../models/recent_file.dart';
import 'file_service.dart';
import 'recent_files_service.dart';

const _operationLabel = 'Opened from another app';

class IncomingShareOutcome {
  const IncomingShareOutcome({
    required this.addedCount,
    required this.skippedUnsupported,
    required this.failed,
  });

  final int addedCount;
  final int skippedUnsupported;
  final int failed;

  bool get hasAdded => addedCount > 0;
}

final incomingShareServiceProvider = Provider<IncomingShareService>((ref) {
  return IncomingShareService(
    fileService: ref.watch(fileServiceProvider),
    recentFilesService: ref.watch(recentFilesServiceProvider),
  );
});

/// Receives Open with / Share intents and imports files into Recent documents.
class IncomingShareService {
  IncomingShareService({
    required FileService fileService,
    required RecentFilesService recentFilesService,
  })  : _fileService = fileService,
        _recentFilesService = recentFilesService;

  final FileService _fileService;
  final RecentFilesService _recentFilesService;

  StreamSubscription<List<SharedMediaFile>>? _mediaSubscription;
  final Set<String> _processedPaths = <String>{};
  bool _listening = false;

  Future<void> startListening({
    required Future<void> Function(IncomingShareOutcome outcome) onOutcome,
  }) async {
    if (_listening) return;
    _listening = true;

    try {
      final initial = await ReceiveSharingIntent.instance.getInitialMedia();
      if (initial.isNotEmpty) {
        final outcome = await _processMediaList(initial);
        await onOutcome(outcome);
        await ReceiveSharingIntent.instance.reset();
      }
    } catch (error, stackTrace) {
      debugPrint('IncomingShareService initial media failed: $error\n$stackTrace');
    }

    _mediaSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen(
      (media) async {
        if (media.isEmpty) return;
        final outcome = await _processMediaList(media);
        await onOutcome(outcome);
      },
      onError: (error, stackTrace) {
        debugPrint('IncomingShareService stream failed: $error\n$stackTrace');
      },
    );
  }

  Future<void> dispose() async {
    await _mediaSubscription?.cancel();
    _mediaSubscription = null;
    _listening = false;
    _processedPaths.clear();
  }

  Future<IncomingShareOutcome> _processMediaList(List<SharedMediaFile> media) async {
    var addedCount = 0;
    var skippedUnsupported = 0;
    var failed = 0;

    for (final item in media) {
      if (item.type == SharedMediaType.text || item.type == SharedMediaType.url) {
        skippedUnsupported++;
        continue;
      }

      final sourcePath = item.path;
      if (sourcePath.isEmpty) {
        failed++;
        continue;
      }

      final dedupeKey = '$sourcePath|${item.type.name}|${item.mimeType ?? ''}';
      if (_processedPaths.contains(dedupeKey)) continue;
      _processedPaths.add(dedupeKey);

      try {
        final recentFile = await importSharedMedia(item);
        if (recentFile == null) {
          skippedUnsupported++;
        } else {
          await _recentFilesService.add(recentFile);
          addedCount++;
        }
      } on AppException {
        failed++;
      } catch (_) {
        failed++;
      }
    }

    return IncomingShareOutcome(
      addedCount: addedCount,
      skippedUnsupported: skippedUnsupported,
      failed: failed,
    );
  }

  Future<RecentFile?> importSharedMedia(SharedMediaFile media) async {
    final sourcePath = media.path;
    if (sourcePath.isEmpty) {
      throw const InvalidFileException('Shared file path is missing.');
    }

    final kind = IncomingFileTypes.detect(
      path: sourcePath,
      mimeType: media.mimeType,
    );
    if (!IncomingFileTypes.isSupported(kind)) {
      return null;
    }

    final suggestedName = _resolveFileName(sourcePath, media);
    final importedPath = await _fileService.importIncomingFile(
      sourcePath: sourcePath,
      suggestedName: suggestedName,
    );
    final size = await _fileService.getFileSize(importedPath);

    return await _recentFilesService.createEntry(
      filePath: importedPath,
      operation: _operationLabel,
      fileSizeBytes: size,
    );
  }

  String _resolveFileName(String sourcePath, SharedMediaFile media) {
    final fromPath = _fileService.getFileName(sourcePath);
    if (fromPath.isNotEmpty && fromPath != sourcePath && fromPath.contains('.')) {
      return fromPath;
    }

    final mime = (media.mimeType ?? '').toLowerCase();
    final ext = switch (true) {
      _ => mime.contains('pdf')
          ? 'pdf'
          : mime.startsWith('image/')
              ? 'jpg'
              : mime.contains('wordprocessingml')
                  ? 'docx'
                  : mime.contains('msword')
                      ? 'doc'
                      : mime.contains('spreadsheetml')
                          ? 'xlsx'
                          : mime.contains('ms-excel')
                              ? 'xls'
                              : _fileService.getExtension(sourcePath),
    };

    if (ext.isEmpty) return 'shared_file';
    return 'shared_file.$ext';
  }
}
