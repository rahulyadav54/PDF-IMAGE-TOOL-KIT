import 'package:flutter/material.dart';

class QualitySliderCard extends StatelessWidget {
  const QualitySliderCard({
    super.key,
    required this.quality,
    required this.onChanged,
    this.supportsQuality = true,
  });

  final int quality;
  final ValueChanged<int> onChanged;
  final bool supportsQuality;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quality',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '$quality%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: quality.toDouble(),
              min: 20,
              max: 100,
              divisions: 16,
              label: '$quality%',
              onChanged: supportsQuality ? (v) => onChanged(v.round()) : null,
            ),
            Text(
              supportsQuality
                  ? 'Lower quality produces smaller files. 100 is best quality.'
                  : 'This format uses lossless encoding. Compression savings may be limited.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
