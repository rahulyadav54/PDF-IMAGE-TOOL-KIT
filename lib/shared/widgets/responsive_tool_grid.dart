import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Responsive grid delegate for tool cards on Home and Tools screens.
abstract final class ResponsiveToolGrid {
  static int crossAxisCount(double width) {
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  static SliverGridDelegate sliverDelegate(
    BuildContext context, {
    bool featured = false,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount(width),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: featured ? 1.58 : 1.42,
    );
  }
}
