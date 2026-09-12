import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../core/utils/incoming_file_types.dart';
import '../models/recent_file.dart';
import '../providers/recent_files_provider.dart';
import '../services/file_actions_service.dart';
import '../services/starred_files_service.dart';
import '../utils/file_opener.dart';

class FileRow extends ConsumerWidget {
  const FileRow({
    super.key,
    required this.file,
    required this.isAvailable,
    this.showDivider = true,
  });

  final RecentFile file;
  final bool isAvailable;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileActions = ref.read(fileActionsServiceProvider);
    final starred = ref.watch(starredPathsProvider);
    final isStarred = starred.contains(file.filePath);
    final kind = IncomingFileTypes.detect(path: file.filePath);
    final typeLabel = IncomingFileTypes.label(kind);
    final iconColor = IncomingFileTypes.accentColor(kind);
    final icon = IncomingFileTypes.icon(kind);

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isAvailable
                ? () => FileOpener.open(
                      context,
                      file.filePath,
                      fileActions: fileActions,
                      title: file.fileName,
                    )
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.listItemV,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.fileName,
                          style: AppTypography.fileName(context).copyWith(
                            color: isAvailable
                                ? null
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAvailable
                              ? '$typeLabel • ${FileSizeFormatter.format(file.fileSizeBytes)}'
                              : 'File is no longer available',
                          style: AppTypography.fileMeta(context).copyWith(
                            color: isAvailable ? null : AppColors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAvailable)
                    Text(
                      DateFormatter.relative(file.processedAt),
                      style: AppTypography.caption(context),
                    ),
                  IconButton(
                    icon: Icon(
                      isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isStarred ? Colors.amber : null,
                    ),
                    tooltip: isStarred ? 'Unstar' : 'Star',
                    onPressed: () =>
                        ref.read(starredPathsProvider.notifier).toggle(file.filePath),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    onSelected: (value) => _handleAction(
                      context,
                      ref,
                      fileActions,
                      value,
                    ),
                    itemBuilder: (context) {
                      if (!isAvailable) {
                        return const [
                          PopupMenuItem(
                            value: 'remove',
                            child: Text('Remove from list'),
                          ),
                        ];
                      }
                      return const [
                        PopupMenuItem(value: 'open', child: Text('Open')),
                        PopupMenuItem(value: 'share', child: Text('Share')),
                        PopupMenuItem(value: 'remove', child: Text('Remove')),
                      ];
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: AppSpacing.screenH + 52,
            endIndent: AppSpacing.screenH,
          ),
      ],
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    FileActionsService fileActions,
    String value,
  ) async {
    if (value == 'remove') {
      await ref.read(recentFilesProvider.notifier).remove(file.id);
      return;
    }
    if (!isAvailable) return;
    try {
      switch (value) {
        case 'open':
          await FileOpener.open(
            context,
            file.filePath,
            fileActions: fileActions,
            title: file.fileName,
          );
        case 'share':
          await fileActions.shareFile(file.filePath);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not complete that action.')),
        );
      }
    }
  }
}
