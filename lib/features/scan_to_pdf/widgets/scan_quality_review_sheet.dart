import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../services/scan_quality_service.dart';
import 'scan_quality_card.dart';

/// Shows scan quality feedback after capture and lets the user retake or keep.
class ScanQualityReviewSheet extends StatelessWidget {
  const ScanQualityReviewSheet({
    super.key,
    required this.report,
    required this.pageLabel,
  });

  final ScanQualityReport report;
  final String pageLabel;

  static Future<bool> show(
    BuildContext context, {
    required ScanQualityReport report,
    required String pageLabel,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ScanQualityReviewSheet(
        report: report,
        pageLabel: pageLabel,
      ),
    );
    return result ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenH,
        right: AppSpacing.screenH,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            pageLabel,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          ScanQualityCard(report: report),
          const SizedBox(height: AppSpacing.lg),
          if (report.shouldRetake) ...[
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Retake'),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Keep anyway'),
            ),
          ] else
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
        ],
      ),
    );
  }
}
