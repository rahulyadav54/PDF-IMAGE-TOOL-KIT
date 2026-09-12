import 'package:flutter/material.dart';

import '../models/pdf_page_config.dart';

class PageConfigPanel extends StatelessWidget {
  const PageConfigPanel({
    super.key,
    required this.config,
    required this.onChanged,
  });

  final PdfPageConfig config;
  final ValueChanged<PdfPageConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    final showOrientation = config.pageSize != PdfPageSizeOption.fitToImage &&
        config.pageSize != PdfPageSizeOption.auto;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Page Settings',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Page Size',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PdfPageSizeOption.values.map((size) {
                return ChoiceChip(
                  label: Text(size.label),
                  selected: config.pageSize == size,
                  onSelected: (selected) {
                    if (selected) {
                      onChanged(config.copyWith(pageSize: size));
                    }
                  },
                );
              }).toList(),
            ),
            if (showOrientation) ...[
              const SizedBox(height: 16),
              Text(
                'Orientation',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              SegmentedButton<PdfPageOrientation>(
                segments: PdfPageOrientation.values
                    .map((o) => ButtonSegment(value: o, label: Text(o.label)))
                    .toList(),
                selected: {config.orientation},
                onSelectionChanged: (selection) {
                  onChanged(config.copyWith(orientation: selection.first));
                },
              ),
            ],
            const SizedBox(height: 8),
            Text(
              config.pageSize == PdfPageSizeOption.auto
                  ? 'Each page uses the best paper size, orientation, and margins.'
                  : config.pageSize.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
