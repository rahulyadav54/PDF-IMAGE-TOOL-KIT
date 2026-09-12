import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/file_size_formatter.dart';
import '../models/recent_file.dart';
import '../providers/recent_files_provider.dart';
import '../services/file_actions_service.dart';
import '../utils/file_opener.dart';

class RecentFileTile extends ConsumerWidget {
  const RecentFileTile({
    super.key,
    required this.file,
    required this.isAvailable,
    this.compact = false,
  });

  final RecentFile file;
  final bool isAvailable;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy • HH:mm');
    final fileActions = ref.read(fileActionsServiceProvider);
    final isImage = fileActions.isImage(file.filePath);

    return Card(
      margin: EdgeInsets.only(bottom: compact ? 8 : 12),
      color: isAvailable ? null : colors.surfaceContainerHighest,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        enabled: isAvailable,
        onTap: isAvailable
            ? () => _openFile(context, fileActions, file.filePath)
            : null,
        leading: CircleAvatar(
          backgroundColor: isAvailable
              ? colors.primaryContainer
              : colors.surfaceContainerHigh,
          child: Icon(
            _iconForType(file.fileType),
            color: isAvailable ? colors.primary : colors.onSurfaceVariant,
            size: 20,
          ),
        ),
        title: Text(
          file.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isAvailable ? null : colors.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          isAvailable
              ? '${file.operation} • ${FileSizeFormatter.format(file.fileSizeBytes)} • ${dateFormat.format(file.processedAt)}'
              : 'File is no longer available',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isAvailable ? null : colors.error,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (!isAvailable) {
              if (value == 'remove') {
                await ref.read(recentFilesProvider.notifier).remove(file.id);
              }
              return;
            }

            switch (value) {
              case 'open':
                await _openFile(context, fileActions, file.filePath);
              case 'share':
                await _shareFile(context, fileActions, file.filePath);
              case 'gallery':
                await _saveToGallery(context, fileActions, file.filePath);
              case 'download':
                await _downloadFile(context, fileActions, file.filePath);
              case 'remove':
                await ref.read(recentFilesProvider.notifier).remove(file.id);
            }
          },
          itemBuilder: (context) => [
            if (isAvailable) ...[
              const PopupMenuItem(value: 'open', child: Text('Open')),
              const PopupMenuItem(value: 'share', child: Text('Share')),
              if (isImage)
                const PopupMenuItem(
                  value: 'gallery',
                  child: Text('Save to Gallery'),
                ),
              const PopupMenuItem(value: 'download', child: Text('Download')),
            ],
            const PopupMenuItem(
              value: 'remove',
              child: Text('Remove from recent'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFile(
    BuildContext context,
    FileActionsService fileActions,
    String path,
  ) async {
    try {
      await FileOpener.open(context, path, fileActions: fileActions);
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  Future<void> _shareFile(
    BuildContext context,
    FileActionsService fileActions,
    String path,
  ) async {
    try {
      await fileActions.shareFile(path);
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  Future<void> _saveToGallery(
    BuildContext context,
    FileActionsService fileActions,
    String path,
  ) async {
    try {
      final result = await fileActions.saveImageToGallery(path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  Future<void> _downloadFile(
    BuildContext context,
    FileActionsService fileActions,
    String path,
  ) async {
    try {
      final result = await fileActions.saveToDownloads(path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  void _showError(BuildContext context, Object error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_userMessage(error))),
    );
  }

  String _userMessage(Object error) {
    if (error is AppException) return error.message;
    return 'Unable to complete this action. Please try again.';
  }

  IconData _iconForType(String fileType) {
    final type = fileType.toLowerCase();
    if (type == 'pdf') return Icons.picture_as_pdf_outlined;
    if (type == 'zip') return Icons.folder_zip_outlined;
    if (['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'].contains(type)) {
      return Icons.image_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }
}
