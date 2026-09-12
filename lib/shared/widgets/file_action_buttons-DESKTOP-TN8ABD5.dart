import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../services/file_actions_service.dart';
import '../utils/file_opener.dart';

/// Standard action row for completed tool outputs: open, share, save, download.
class FileActionButtons extends StatelessWidget {
  const FileActionButtons({
    super.key,
    required this.filePath,
    required this.fileActions,
    this.trailing,
  });

  final String filePath;
  final FileActionsService fileActions;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isImage = fileActions.isImage(filePath);
    final isPdf = fileActions.isPdf(filePath);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => _run(
            context,
            () => FileOpener.open(
              context,
              filePath,
              fileActions: fileActions,
            ),
          ),
          icon: Icon(isPdf ? Icons.visibility_outlined : Icons.open_in_new),
          label: Text(isPdf ? 'View PDF' : isImage ? 'Open Image' : 'Open'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _run(context, () => fileActions.shareFile(filePath)),
          icon: const Icon(Icons.share_outlined),
          label: Text(isPdf ? 'Share PDF' : isImage ? 'Share Image' : 'Share'),
        ),
        if (isImage) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _run(
              context,
              () => fileActions.saveImageToGallery(filePath),
            ),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Save to Gallery'),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _run(
            context,
            () => fileActions.saveToDownloads(filePath),
          ),
          icon: const Icon(Icons.download_outlined),
          label: Text(
            isPdf ? 'Download PDF' : isImage ? 'Download Image' : 'Download',
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(height: 8),
          trailing!,
        ],
      ],
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<dynamic> Function() action,
  ) async {
    try {
      final result = await action();
      if (!context.mounted) return;
      if (result is FileSaveResult) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message(error))),
      );
    }
  }

  String _message(Object error) {
    if (error is AppException) return error.message;
    return 'Unable to complete this action. Please try again.';
  }
}
