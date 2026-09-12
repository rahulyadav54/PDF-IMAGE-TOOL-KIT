import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../services/scan_quality_service.dart';

class ScanQualityCard extends StatelessWidget {
  const ScanQualityCard({super.key, required this.report});

  final ScanQualityReport report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = report.score >= 70
        ? Colors.green
        : report.score >= 50
            ? Colors.orange
            : scheme.error;

    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Scan quality', style: AppTypography.cardTitle(context)),
                const Spacer(),
                Text(
                  '${report.score} / 100',
                  style: AppTypography.cardTitle(context).copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(report.summary, style: AppTypography.cardSubtitle(context)),
            const SizedBox(height: AppSpacing.md),
            ...report.indicators.map(
              (indicator) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      indicator.passed
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_outlined,
                      size: 18,
                      color: indicator.passed ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        indicator.warning ?? indicator.label,
                        style: AppTypography.cardSubtitle(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (report.shouldRetake) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Hold steady and try again for better results.',
                style: AppTypography.cardSubtitle(context).copyWith(
                  color: scheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
