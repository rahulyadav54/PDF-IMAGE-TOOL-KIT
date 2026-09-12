import 'package:flutter/material.dart';

import '../../scan_to_pdf/models/scan_enhance_kind.dart';
import '../models/image_pdf_processing_options.dart';

class ImagePdfConfigPanel extends StatelessWidget {
  const ImagePdfConfigPanel({
    super.key,
    required this.options,
    required this.onChanged,
  });

  final ImagePdfProcessingOptions options;
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
              'Processing',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            _RadioGroup<ImagePdfProcessingMode>(
              value: options.processingMode,
              options: ImagePdfProcessingMode.values,
              labelBuilder: (mode) => mode.label,
              onChanged: (mode) => onChanged(options.copyWith(processingMode: mode)),
            ),
            const SizedBox(height: 20),
            Text(
              'Quality',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 20),
            Text(
              'PDF Size',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ImagePdfSizePreset>(
              segments: ImagePdfSizePreset.values
                  .map(
                    (preset) => ButtonSegment(
                      value: preset,
                      label: Text(preset.label, style: const TextStyle(fontSize: 11)),
                    ),
                  )
                  .toList(),
              selected: {options.sizePreset},
              onSelectionChanged: (value) =>
                  onChanged(options.copyWith(sizePreset: value.first)),
            ),
            if (options.processingMode != ImagePdfProcessingMode.original) ...[
              const SizedBox(height: 20),
              Text(
                'Enhancement style',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ScanEnhanceKind.auto,
                  ScanEnhanceKind.magicColor,
                  ScanEnhanceKind.document,
                  ScanEnhanceKind.grayscale,
                  ScanEnhanceKind.blackWhite,
                ].map((kind) {
                  final selected = options.enhancementKind == kind;
                  return ChoiceChip(
                    label: Text(_kindLabel(kind)),
                    selected: selected,
                    onSelected: (_) =>
                        onChanged(options.copyWith(enhancementKind: kind)),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Max width ~${options.effectiveMaxDimension}px • JPEG ${options.effectiveJpegQuality}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _kindLabel(ScanEnhanceKind kind) => switch (kind) {
        ScanEnhanceKind.auto => 'Auto',
        ScanEnhanceKind.magicColor => 'Magic Color',
        ScanEnhanceKind.document => 'Document',
        ScanEnhanceKind.grayscale => 'Grayscale',
        ScanEnhanceKind.blackWhite => 'B&W',
        ScanEnhanceKind.original => 'Original',
      };
}

class _RadioGroup<T> extends StatelessWidget {
  const _RadioGroup({
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T value;
  final List<T> options;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options
          .map(
            (option) => RadioListTile<T>(
              value: option,
              groupValue: value,
              onChanged: (selected) {
                if (selected != null) onChanged(selected);
              },
              title: Text(labelBuilder(option)),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          )
          .toList(),
    );
  }
}
