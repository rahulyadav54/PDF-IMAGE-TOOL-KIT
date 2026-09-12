import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/tool_icon_badge.dart';

class ProCard extends StatelessWidget {
  const ProCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/pro'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEDE9FE), Color(0xFFE0E7FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.proBorder),
            boxShadow: AppShadows.elevated,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ToolIconBadge(
                  icon: Icons.workspace_premium_rounded,
                  accentColor: AppColors.purple,
                  dimension: 56,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Tools Unlocked',
                        style: AppTypography.bannerTitle(context),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Free forever · No ads · Unlimited processing',
                        style: AppTypography.caption(context),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: () => context.push('/pro'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Learn More'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
