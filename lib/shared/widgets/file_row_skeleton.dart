import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Subtle loading placeholder for recent file rows.
class FileRowSkeleton extends StatelessWidget {
  const FileRowSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shimmer = scheme.surfaceContainerHighest;

    return Column(
      children: List.generate(count, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: AppSpacing.listItemV,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 180),
                      decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 11,
                      width: 100,
                      decoration: BoxDecoration(
                        color: shimmer.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
