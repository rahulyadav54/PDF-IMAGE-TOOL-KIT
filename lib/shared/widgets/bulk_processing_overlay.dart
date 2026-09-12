import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
class BulkProcessingOverlay extends StatelessWidget {
  const BulkProcessingOverlay({
    super.key,
    required this.title,
    required this.message,
    this.progress,
    this.progressLabel,
    this.detail,
    this.onCancel,
  });

  final String title;
  final String message;
  final double? progress;
  final String? progressLabel;
  final String? detail;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: message,
      liveRegion: true,
      child: ColoredBox(
        color: colors.scrim.withValues(alpha: 0.58),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(AppSpacing.xxl),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (progress != null) ...[
                    SizedBox(
                      width: 240,
                      child: LinearProgressIndicator(value: progress),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    message,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (progressLabel != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      progressLabel!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (detail != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      detail!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                  if (onCancel != null) ...[
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: onCancel,
                      child: const Text('Cancel'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
