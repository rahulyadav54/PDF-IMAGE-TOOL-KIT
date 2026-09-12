import 'package:flutter/material.dart';

import '../../scan_to_pdf/models/scan_enhance_kind.dart';
import '../models/image_pdf_processing_options.dart';

class ImagePdfProcessingPanel extends StatelessWidget {
  const ImagePdfProcessingPanel({
    super.key,
    required this.options,
    required this.imageCount,
    required this.onChanged,
  });

  final ImagePdfProcessingOptions options;
  final int imageCount;
  final ValueChanged<ImagePdfProcessingOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create PDF',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '$imageCount image${imageCount == 1 ? '' : 's'} selected',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text('Processing', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            ...ImagePdfProcessingMode.values.map(
              (mode) => RadioListTile<ImagePdfProcessingMode>(
                value: mode,
                groupValue: options.processingMode,
                onChanged: (value) {
                  if (value == null) return;
                  onChanged(options.copyWith(processingMode: value));
                },
                title: Text(mode.label),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (options.processingMode != ImagePdfProcessingMode.original) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<ScanEnhanceKind>(
                value: options.enhancementKind,
                decoration: const InputDecoration(
                  labelText: 'Enhancement style',
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(
                    value: ScanEnhanceKind.auto,
                    child: Text('Auto Enhance'),
                  ),
                  DropdownMenuItem(
                    value: ScanEnhanceKind.magicColor,
                    child: Text('Magic Color'),
                  ),
                  DropdownMenuItem(
                    value: ScanEnhanceKind.document,
                    child: Text('Document'),
                  ),
                  DropdownMenuItem(
                    value: ScanEnhanceKind.grayscale,
                    child: Text('Grayscale'),
                  ),
                  DropdownMenuItem(
                    value: ScanEnhanceKind.blackWhite,
                    child: Text('B&W'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  onChanged(options.copyWith(enhancementKind: value));
                },
              ),
            ],
            const SizedBox(height: 16),
            Text('Quality', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<ImagePdfQuality>(
              segments: ImagePdfQuality.values
                  .map(
                    (q) => ButtonSegment(
                      value: q,
                      label: Text(q.label, style: const TextStyle(fontSize: 11)),
                    ),
                  )
                  .toList(),
              selected: {options.quality},
              onSelectionChanged: (value) =>
                  onChanged(options.copyWith(quality: value.first)),
            ),
            const SizedBox(height: 16),
            Text('PDF Size', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<ImagePdfSizePreset>(
              segments: ImagePdfSizePreset.values
                  .map(
                    (s) => ButtonSegment(
                      value: s,
                      label: Text(s.label, style: const TextStyle(fontSize: 11)),
                    ),
                  )
                  .toList(),
              selected: {options.sizePreset},
              onSelectionChanged: (value) =>
                  onChanged(options.copyWith(sizePreset: value.first)),
            ),
          ],
        ),
      ),
    );
  }
}
