import 'package:flutter/material.dart';

import '../models/image_export_format.dart';

class ExportFormatSelector extends StatelessWidget {
  const ExportFormatSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ImageExportFormat selected;
  final ValueChanged<ImageExportFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Output Format',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ImageExportFormat>(
              segments: ImageExportFormat.values
                  .map((f) => ButtonSegment(value: f, label: Text(f.label)))
                  .toList(),
              selected: {selected},
              onSelectionChanged: (selection) => onChanged(selection.first),
            ),
          ],
        ),
      ),
    );
  }
}
