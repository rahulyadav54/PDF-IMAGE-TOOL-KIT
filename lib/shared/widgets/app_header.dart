import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.subtitle = AppConstants.appTagline,
    this.trailing,
    this.showAppName = true,
  });

  final String subtitle;
  final Widget? trailing;
  final bool showAppName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showAppName)
                  Text(
                    AppConstants.appNameShort,
                    style: AppTypography.caption(context).copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                if (showAppName) const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: AppTypography.pageTitle(context)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
