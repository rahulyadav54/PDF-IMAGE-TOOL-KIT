import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class PrivacyCard extends StatelessWidget {
  const PrivacyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.iconContainerBg(AppColors.green),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 20,
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your files stay on your device',
                    style: AppTypography.cardTitle(context),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Private • Offline • No uploads',
                    style: AppTypography.cardSubtitle(context),
                  ),
                ],
              ),
            ),
            Icon(Icons.offline_bolt_outlined, size: 18, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
