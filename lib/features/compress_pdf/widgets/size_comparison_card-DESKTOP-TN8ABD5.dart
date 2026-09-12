import 'package:flutter/material.dart';

import '../../../core/utils/file_size_formatter.dart';

class SizeComparisonCard extends StatelessWidget {
  const SizeComparisonCard({
    super.key,
    required this.originalBytes,
    this.estimatedBytes,
    this.compressedBytes,
    this.showEstimate = false,
    this.estimateSubtitle = 'Approximate — actual size depends on PDF content',
  });

  final int originalBytes;
  final int? estimatedBytes;
  final int? compressedBytes;
  final bool showEstimate;
  final String estimateSubtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Row(
              label: 'Original',
              value: FileSizeFormatter.format(originalBytes),
            ),
            if (showEstimate && estimatedBytes != null) ...[
              const Divider(height: 24),
              _Row(
                label: 'Estimated Size',
                value: FileSizeFormatter.format(estimatedBytes!),
                subtitle: estimateSubtitle,
                valueColor: colors.tertiary,
              ),
              if (estimatedBytes! < originalBytes) ...[
                const SizedBox(height: 8),
                Text(
                  'Estimated savings: ${FileSizeFormatter.savedPercent(originalBytes, estimatedBytes!)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ],
            if (compressedBytes != null) ...[
              const Divider(height: 24),
              _Row(
                label: 'Compressed',
                value: FileSizeFormatter.format(compressedBytes!),
                valueColor: colors.primary,
              ),
              if (compressedBytes! < originalBytes) ...[
                const SizedBox(height: 8),
                Text(
                  'Saved: ${FileSizeFormatter.savedPercent(originalBytes, compressedBytes!)}%',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'This PDF could not be reduced further at this quality level.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyLarge),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
            ],
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}
