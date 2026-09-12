import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
/// App logo used in headers, splash, and settings.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 48,
    this.showBackground = false,
    this.borderRadius = 14,
  });

  final double size;
  final bool showBackground;
  final double borderRadius;

  static const _assetPath = 'assets/branding/splash_logo.png';

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        _assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.picture_as_pdf_rounded,
          size: size * 0.62,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );

    if (!showBackground) return image;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.electricBlue,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricBlue.withValues(alpha: 0.25),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: image,
    );
  }
}
