import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/tool_type.dart';
import '../../shared/services/file_actions_service.dart';
import '../../shared/services/open_with_service.dart';

class OpenWithScreen extends ConsumerWidget {
  const OpenWithScreen({
    super.key,
    required this.file,
  });

  final OpenWithFile file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileActions = ref.watch(fileActionsServiceProvider);
    final isPdf = fileActions.isPdf(file.path);
    final isImage = fileActions.isImage(file.path);
    final actions = isPdf
        ? _pdfActions
        : isImage
            ? _imageActions
            : const <_OpenWithAction>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open With'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _FileSummaryCard(
              file: file,
              isPdf: isPdf,
              isImage: isImage,
            ),
            const SizedBox(height: 24),
            Text(
              isPdf
                  ? 'Choose what to do with this PDF'
                  : isImage
                      ? 'Choose what to do with this image'
                      : 'This file type is not supported by the built-in tools',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isPdf || isImage
                  ? 'The file was copied into private app storage and is ready to process.'
                  : 'You can still open it with another app or save a copy to Downloads.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (actions.isNotEmpty) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                ),
                itemCount: actions.length,
                itemBuilder: (context, index) {
                  final action = actions[index];
                  return _ActionCard(
                    action: action,
                    onPressed: () =>
                        context.push(action.tool.route, extra: file.path),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
            OutlinedButton.icon(
              onPressed: () => _openExternally(context, fileActions),
              icon: const Icon(Icons.open_in_new_outlined),
              label: const Text('Open with another app'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _saveToDownloads(context, fileActions),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Save a copy to Downloads'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openExternally(
    BuildContext context,
    FileActionsService fileActions,
  ) async {
    try {
      await fileActions.openFile(file.path);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this file externally.')),
      );
    }
  }

  Future<void> _saveToDownloads(
    BuildContext context,
    FileActionsService fileActions,
  ) async {
    try {
      final result = await fileActions.saveToDownloads(file.path);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save this file.')),
      );
    }
  }
}

const List<_OpenWithAction> _pdfActions = [
  _OpenWithAction(
    tool: ToolType.compressPdf,
    icon: Icons.compress_rounded,
    label: 'Compress',
  ),
  _OpenWithAction(
    tool: ToolType.pdfToImage,
    icon: Icons.image_outlined,
    label: 'PDF to Image',
  ),
  _OpenWithAction(
    tool: ToolType.pdfPageEditor,
    icon: Icons.rotate_right_rounded,
    label: 'Rotate & Reorder',
  ),
  _OpenWithAction(
    tool: ToolType.protectPdf,
    icon: Icons.lock_rounded,
    label: 'Lock PDF',
  ),
  _OpenWithAction(
    tool: ToolType.editPdf,
    icon: Icons.edit_note_rounded,
    label: 'Edit PDF',
  ),
  _OpenWithAction(
    tool: ToolType.splitPdf,
    icon: Icons.content_cut_rounded,
    label: 'Split PDF',
  ),
];

const List<_OpenWithAction> _imageActions = [
  _OpenWithAction(
    tool: ToolType.imageConvert,
    icon: Icons.transform_rounded,
    label: 'Convert Format',
  ),
  _OpenWithAction(
    tool: ToolType.imageCompress,
    icon: Icons.photo_size_select_small_rounded,
    label: 'Compress Image',
  ),
  _OpenWithAction(
    tool: ToolType.imageResize,
    icon: Icons.aspect_ratio_rounded,
    label: 'Resize Image',
  ),
  _OpenWithAction(
    tool: ToolType.imageToPdf,
    icon: Icons.picture_as_pdf_rounded,
    label: 'Image to PDF',
  ),
  _OpenWithAction(
    tool: ToolType.imageStitch,
    icon: Icons.view_agenda_outlined,
    label: 'Stitch Images',
  ),
  _OpenWithAction(
    tool: ToolType.idPhoto,
    icon: Icons.badge_rounded,
    label: 'ID Photo',
  ),
];

class _FileSummaryCard extends StatelessWidget {
  const _FileSummaryCard({
    required this.file,
    required this.isPdf,
    required this.isImage,
  });

  final OpenWithFile file;
  final bool isPdf;
  final bool isImage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final extension =
        File(file.path).uri.pathSegments.last.split('.').skip(1).join('.');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: isPdf
                  ? AppColors.red.withValues(alpha: 0.12)
                  : isImage
                      ? AppColors.green.withValues(alpha: 0.12)
                      : colors.secondaryContainer,
              child: Icon(
                isPdf
                    ? Icons.picture_as_pdf_outlined
                    : isImage
                        ? Icons.image_outlined
                        : Icons.insert_drive_file_outlined,
                color: isPdf
                    ? AppColors.red
                    : isImage
                        ? AppColors.green
                        : colors.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (extension.isNotEmpty) extension.toUpperCase(),
                      if (file.mimeType.isNotEmpty) file.mimeType,
                    ].where((value) => value.isNotEmpty).join(' • '),
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.action,
    required this.onPressed,
  });

  final _OpenWithAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(action.icon, color: action.tool.accentColor),
              const Spacer(),
              Text(
                action.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenWithAction {
  const _OpenWithAction({
    required this.tool,
    required this.icon,
    required this.label,
  });

  final ToolType tool;
  final IconData icon;
  final String label;
}
