import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../models/processing_job.dart';

/// Standard processing UI used across bulk jobs and workflows.
class ProcessingScreen extends StatelessWidget {
  const ProcessingScreen({
    super.key,
    required this.job,
    this.onCancel,
    this.onRetryFailed,
    this.onViewFailed,
  });

  final ProcessingJob job;
  final VoidCallback? onCancel;
  final VoidCallback? onRetryFailed;
  final VoidCallback? onViewFailed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = job.progress;

    return Semantics(
      label: job.title,
      liveRegion: true,
      child: ColoredBox(
        color: colors.scrim.withValues(alpha: 0.58),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(AppSpacing.xxl),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      job.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (progress != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: LinearProgressIndicator(value: progress),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        job.progressLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (progress > 0)
                        Text(
                          '${(progress * 100).round()}%',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ] else
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'Completed',
                      value: '${job.completedItems}',
                      icon: Icons.check_circle_outline,
                    ),
                    _StatRow(
                      label: 'Processing',
                      value: job.isActive ? '1' : '0',
                      icon: Icons.autorenew,
                    ),
                    _StatRow(
                      label: 'Remaining',
                      value: '${job.remainingItems}',
                      icon: Icons.radio_button_unchecked,
                    ),
                    if (job.failedItems > 0)
                      _StatRow(
                        label: 'Failed',
                        value: '${job.failedItems}',
                        icon: Icons.error_outline,
                        color: colors.error,
                      ),
                    if (job.currentLabel != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        job.currentLabel!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                    if (job.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        job.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.error),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (onCancel != null && job.isActive)
                      TextButton(
                        onPressed: onCancel,
                        child: const Text('Cancel'),
                      ),
                    if (onRetryFailed != null && job.failedItems > 0)
                      TextButton(
                        onPressed: onRetryFailed,
                        child: const Text('Retry failed'),
                      ),
                    if (onViewFailed != null && job.failedLabels.isNotEmpty)
                      TextButton(
                        onPressed: onViewFailed,
                        child: const Text('View failed'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
