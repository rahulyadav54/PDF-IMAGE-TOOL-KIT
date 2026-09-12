import 'package:flutter/material.dart';

import '../models/compression_level.dart';

class CompressionLevelSelector extends StatelessWidget {
  const CompressionLevelSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final CompressionLevel selected;
  final ValueChanged<CompressionLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: CompressionLevel.values.map((level) {
        final isSelected = level == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onChanged(level),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Radio<CompressionLevel>(
                      value: level,
                      groupValue: selected,
                      onChanged: (v) {
                        if (v != null) onChanged(v);
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level.label,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            level.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          if (level.useRasterize)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Optimizes image-heavy pages',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Preserves text and vector content',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
