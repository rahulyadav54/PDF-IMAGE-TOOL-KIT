import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/company_branding.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Use')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Text(
            'Terms of Use',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text(
            'By installing or using ${AppConstants.appName}, you agree to these terms.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text('License', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'We grant you a personal, non-transferable license to use the app on '
            'devices you own or control, subject to Google Play terms and these '
            'conditions.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text('Your content', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'You retain ownership of your files. You are responsible for the '
            'content you process and for complying with applicable laws, including '
            'copyright and privacy obligations.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text('Pro and refunds', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Pro purchases are handled by Google Play. Refund requests must be '
            'submitted through Google Play according to Google\'s refund policies.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text('Disclaimer', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'The app is provided "as is" without warranties. Document processing '
            'results may vary by input quality, device performance, and file type. '
            'Always keep backups of important documents.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text('Contact', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            '${AppConstants.supportEmail}\nPhone: ${AppConstants.supportPhone}',
            style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          const CompanyBranding(style: CompanyBrandingStyle.about),
        ],
      ),
    );
  }
}
