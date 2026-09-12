import 'package:flutter/material.dart';

import '../../../core/utils/file_size_formatter.dart';
import '../models/batch_file_item.dart';

class BatchFilesList extends StatelessWidget {
  const BatchFilesList({
    super.key,
    required this.items,
    required this.onRemove,
  });

  final List<BatchFileItem> items;
  final void Function(BatchFileItem item) onRemove;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final position = (index + 1).toString().padLeft(2, '0');
        final subtitle = item.pageCount != null
            ? '${item.pageCount} pages • ${FileSizeFormatter.format(item.fileSizeBytes)}'
            : FileSizeFormatter.format(item.fileSizeBytes);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(position, style: const TextStyle(fontSize: 12)),
            ),
            title: Text(
              item.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(subtitle),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove file',
              onPressed: () => onRemove(item),
            ),
          ),
        );
      },
    );
  }
}
