import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/company_branding.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
          const SizedBox(height: AppSpacing.sectionGap),
          Text(
            'PDF & Image Toolbox is designed with privacy in mind. Core file '
            'processing happens locally on your device. We do not upload your PDFs, '
            'images, or documents to our servers for processing.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text('Local Processing', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Compression, conversion, merging, splitting, scanning, and batch '
            'operations are performed entirely on your device.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text('Permissions', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Camera access is requested only when you start document scanning. '
            'File selection uses the Android system picker (Storage Access Framework) '
            'so the app does not need broad storage access for picking files.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text('Local History', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Recent files are stored locally on your device as metadata only '
            '(filename, path, size, and operation type). You can clear this '
            'history anytime from Settings or Recent Files.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text('Third-Party Services', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Document scanning may use on-device ML components provided by Google '
            'or device manufacturers. These components may use network connectivity '
            'when applicable. This app does not include ads or in-app purchases.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text('Data Backup', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Android backup is disabled for this app to reduce the risk of '
            'restoring tampered history data.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text('Contact', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'For privacy questions, contact ${AppConstants.companyName}.',
            style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          const CompanyBranding(style: CompanyBrandingStyle.about),
          const SizedBox(height: AppSpacing.sectionGap),
        ],
      ),
    );
  }
}
