import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/company_branding.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Future<void> _openPolicyUrl(BuildContext context) async {
    final uri = Uri.parse(AppConstants.privacyPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppConstants.privacyPolicyUrl)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Text(
            'Privacy Policy',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Last updated: March 2026',
            style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text(
            '${AppConstants.appName} is built for on-device document work. Your PDFs, '
            'images, and scans are processed locally on your phone. We do not upload '
            'your files to our servers for conversion, compression, or editing.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text('What stays on your device', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'File processing, scanning, enhancement, OCR, batch tools, and PDF '
            'generation run entirely on your device. Recent file history, app '
            'preferences, Pro status cache, and optional vault entries are stored '
            'locally. You can clear history and cache from Settings.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text('Permissions', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Camera access is requested only when you start document scanning. '
            'File picking uses the Android system picker. Biometric app lock is '
            'optional and uses your device secure hardware when enabled.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text('Advertising (free version)', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'The free app may show ads through Google AdMob. AdMob may collect '
            'device identifiers and usage data according to Google\'s policies. '
            'We request consent where required through Google\'s User Messaging '
            'Platform. Pro removes ads.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text('In-app purchases', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Pro upgrades are processed by Google Play Billing. Google handles '
            'payment information. We receive purchase tokens to verify Pro access '
            'on your device. We do not store card or bank details.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text('Third-party SDKs', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'The app uses Google Mobile Ads, Google Play Billing, Google ML Kit '
            '(on-device text recognition), and Syncfusion PDF components. These '
            'services may process limited technical data needed to provide ads, '
            'billing, or on-device features.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text('Data backup', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Android backup is disabled for this app to reduce the risk of '
            'restoring sensitive local history or vault metadata.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text('Contact', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Questions about privacy: ${AppConstants.supportEmail}',
            style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => _openPolicyUrl(context),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('View online policy'),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          const CompanyBranding(style: CompanyBrandingStyle.about),
          const SizedBox(height: AppSpacing.sectionGap),
        ],
      ),
    );
  }
}
