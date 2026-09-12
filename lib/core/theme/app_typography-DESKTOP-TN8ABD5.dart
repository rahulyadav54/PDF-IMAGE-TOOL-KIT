import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static TextStyle greeting(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            fontSize: 15,
          );

  static TextStyle pageTitle(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall!.copyWith(
            fontWeight: FontWeight.w700,
            color: _primaryText(context),
            letterSpacing: -0.4,
            height: 1.2,
          );

  static TextStyle screenTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.w700,
            color: _primaryText(context),
            letterSpacing: -0.3,
          );

  static TextStyle sectionTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w700,
            color: _primaryText(context),
            letterSpacing: -0.1,
          );

  static TextStyle cardTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: _primaryText(context),
            height: 1.25,
          );

  static TextStyle cardSubtitle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(
            color: AppColors.textSecondary,
            height: 1.35,
            fontSize: 12,
          );

  static TextStyle body(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!.copyWith(height: 1.45);

  static TextStyle caption(BuildContext context) =>
      Theme.of(context).textTheme.labelMedium!.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          );

  static TextStyle fileName(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            height: 1.2,
          );

  static TextStyle fileMeta(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          );

  static TextStyle display(BuildContext context) => pageTitle(context);
  static TextStyle headline(BuildContext context) => screenTitle(context);
  static TextStyle toolTitle(BuildContext context) => cardTitle(context);
  static TextStyle toolSubtitle(BuildContext context) => cardSubtitle(context);
  static TextStyle bannerTitle(BuildContext context) => cardTitle(context);

  static Color _primaryText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : AppColors.deepNavy;
  }
}
