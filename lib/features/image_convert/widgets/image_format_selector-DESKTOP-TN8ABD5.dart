import 'package:flutter/material.dart';

import '../../../shared/models/image_format.dart';

class ImageFormatSelector extends StatelessWidget {
  const ImageFormatSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.exclude,
  });

  final ImageFormat selected;
  final ValueChanged<ImageFormat> onChanged;
  final ImageFormat? exclude;

  @override
  Widget build(BuildContext context) {
    final formats = ImageFormat.values
        .where((f) => f != exclude && f.supportsEncoding)
        .toList();

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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: formats.map((format) {
                final isSelected = format == selected;
                return ChoiceChip(
                  label: Text(format.label),
                  selected: isSelected,
                  onSelected: (_) => onChanged(format),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
