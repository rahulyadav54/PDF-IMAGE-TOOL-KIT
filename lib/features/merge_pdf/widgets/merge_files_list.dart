import 'package:flutter/material.dart';

import '../../../core/utils/file_size_formatter.dart';
import '../models/merge_pdf_item.dart';

class MergeFilesList extends StatelessWidget {
  const MergeFilesList({
    super.key,
    required this.items,
    required this.onReorder,
    required this.onRemove,
  });

  final List<MergePdfItem> items;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(MergePdfItem item) onRemove;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final item = items[index];
        final position = (index + 1).toString().padLeft(2, '0');

        return Card(
          key: ValueKey(item.id),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(position, style: const TextStyle(fontSize: 12)),
            ),
            title: Text(
              item.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${item.pageCount} pages • ${FileSizeFormatter.format(item.fileSizeBytes)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove file',
                  onPressed: () => onRemove(item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
