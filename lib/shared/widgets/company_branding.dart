import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import 'app_logo.dart';

enum CompanyBrandingStyle { compact, splash, about }

/// Reusable ZAYA CODE HUB branding for splash, home footer, and settings.
class CompanyBranding extends StatelessWidget {
  const CompanyBranding({
    super.key,
    this.style = CompanyBrandingStyle.compact,
    this.lightText = false,
  });

  final CompanyBrandingStyle style;
  final bool lightText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = lightText
        ? Colors.white.withValues(alpha: 0.72)
        : colors.onSurfaceVariant;
    final accent = lightText ? Colors.white : colors.primary;

    switch (style) {
      case CompanyBrandingStyle.splash:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppConstants.companyCreditLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: muted,
                    letterSpacing: 0.4,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              AppConstants.companyName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
            ),
          ],
        );
      case CompanyBrandingStyle.about:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.primaryContainer.withValues(alpha: 0.55),
                colors.secondaryContainer.withValues(alpha: 0.35),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppLogo(size: 40, borderRadius: 10),
                  const SizedBox(width: 12),
                  Text(
                    AppConstants.companyName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppConstants.companyCredit,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                AppConstants.copyright,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      case CompanyBrandingStyle.compact:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppConstants.companyPowered,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              AppConstants.copyright,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: muted.withValues(alpha: 0.85),
                  ),
            ),
          ],
        );
    }
  }
}
