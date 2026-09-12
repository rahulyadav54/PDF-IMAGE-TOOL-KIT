import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.subtitle = 'Everything you need for your files.',
    this.trailing,
    this.showGreeting = true,
  });

  final String subtitle;
  final Widget? trailing;
  final bool showGreeting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.sm,
        AppSpacing.screenH,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showGreeting)
                  Text(
                    '${DateFormatter.timeOfDayGreeting()} 👋',
                    style: AppTypography.greeting(context),
                  ),
                if (showGreeting) const SizedBox(height: 4),
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
