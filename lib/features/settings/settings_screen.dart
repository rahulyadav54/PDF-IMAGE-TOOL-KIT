import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../features/compress_pdf/models/compression_level.dart';
import '../../features/image_to_pdf/models/image_pdf_processing_options.dart';
import '../../features/pdf_to_image/models/image_export_format.dart';
import '../../shared/providers/app_preferences_provider.dart';
import '../../shared/providers/locale_provider.dart';
import '../../shared/providers/purchase_provider.dart';
import '../../shared/providers/recent_files_provider.dart';
import '../../shared/services/app_lock_service.dart';
import '../../shared/services/cache_maintenance_service.dart';
import '../../shared/services/entitlement_service.dart';
import '../../shared/widgets/company_branding.dart';
import '../../shared/widgets/settings_row.dart';
import 'widgets/preference_picker_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePref = ref.watch(themePreferenceProvider);
    final appPrefs = ref.watch(appPreferencesProvider);
    final isPro = ref.watch(entitlementsProvider).valueOrNull?.isPro ?? false;
    final purchaseState = ref.watch(purchaseUiProvider);
    final appLockEnabled = ref.watch(appLockEnabledProvider);
    final locale = ref.watch(localeProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.sm,
              AppSpacing.screenH,
              AppSpacing.md,
            ),
            child: Text('Settings', style: AppTypography.screenTitle(context)),
          ),
          const SettingsSection(title: 'General'),
          ...AppThemePreference.values.map(
            (pref) => RadioListTile<AppThemePreference>(
              title: Text(pref.label),
              value: pref,
              groupValue: themePref,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              onChanged: (value) {
                if (value != null) {
                  ref.read(themePreferenceProvider.notifier).setPreference(value);
                }
              },
            ),
          ),
          const SettingsRow(
            icon: Icons.folder_outlined,
            title: 'Default file location',
            subtitle: 'App documents folder',
          ),
          SettingsRow(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: locale?.languageCode == 'es'
                ? 'Español'
                : locale?.languageCode == 'hi'
                    ? 'हिन्दी'
                    : 'English',
            onTap: () async {
              final selected = await showPreferencePicker<String>(
                context: context,
                title: 'Language',
                selected: locale?.languageCode ?? 'en',
                options: const [
                  (label: 'English', subtitle: 'Default', value: 'en'),
                  (label: 'Español', subtitle: 'Spanish', value: 'es'),
                  (label: 'हिन्दी', subtitle: 'Hindi', value: 'hi'),
                ],
              );
              if (selected != null) {
                await ref.read(localeProvider.notifier).setLocale(Locale(selected));
              }
            },
          ),
          SettingsRow(
            icon: Icons.fingerprint_outlined,
            title: 'App lock',
            subtitle: appLockEnabled ? 'Biometric required' : 'Off',
            trailing: Switch(
              value: appLockEnabled,
              onChanged: (value) async {
                if (value) {
                  final supported =
                      await ref.read(appLockServiceProvider).isDeviceSupported();
                  if (!supported) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Biometric authentication is not available.'),
                      ),
                    );
                    return;
                  }
                  final ok = await ref.read(appLockServiceProvider).authenticate();
                  if (!ok) return;
                }
                await ref.read(appLockEnabledProvider.notifier).setEnabled(value);
              },
            ),
          ),
          const Divider(height: 24),
          const SettingsSection(title: 'PDF'),
          SettingsRow(
            icon: Icons.high_quality_outlined,
            title: 'Default PDF quality',
            subtitle: appPrefs.pdfQualitySubtitle,
            onTap: () async {
              final selected = await showPreferencePicker<ImagePdfQuality>(
                context: context,
                title: 'Default PDF quality',
                selected: appPrefs.pdfQuality,
                options: ImagePdfQuality.values
                    .map(
                      (q) => (
                        label: q.label,
                        subtitle: switch (q) {
                          ImagePdfQuality.standard => 'Smaller scan and PDF files',
                          ImagePdfQuality.high => 'Balanced clarity and size',
                          ImagePdfQuality.maximum => 'Best clarity, larger files',
                        },
                        value: q,
                      ),
                    )
                    .toList(),
              );
              if (selected != null) {
                await ref.read(appPreferencesProvider.notifier).setPdfQuality(selected);
              }
            },
          ),
          SettingsRow(
            icon: Icons.compress_outlined,
            title: 'Compression level',
            subtitle: appPrefs.compressionSubtitle,
            onTap: () async {
              final selected = await showPreferencePicker<CompressionLevel>(
                context: context,
                title: 'Default compression level',
                selected: appPrefs.compressionLevel,
                options: CompressionLevel.values
                    .map(
                      (level) => (
                        label: level.label,
                        subtitle: level.description,
                        value: level,
                      ),
                    )
                    .toList(),
              );
              if (selected != null) {
                await ref
                    .read(appPreferencesProvider.notifier)
                    .setCompressionLevel(selected);
              }
            },
          ),
          SettingsRow(
            icon: Icons.image_outlined,
            title: 'PDF to image format',
            subtitle: appPrefs.exportFormatSubtitle,
            onTap: () async {
              final selected = await showPreferencePicker<ImageExportFormat>(
                context: context,
                title: 'Default export format',
                selected: appPrefs.exportFormat,
                options: ImageExportFormat.values
                    .map(
                      (format) => (
                        label: format.label,
                        subtitle: format == ImageExportFormat.png
                            ? 'Lossless PNG pages'
                            : 'Smaller JPG pages',
                        value: format,
                      ),
                    )
                    .toList(),
              );
              if (selected != null) {
                await ref.read(appPreferencesProvider.notifier).setExportFormat(selected);
              }
            },
          ),
          const Divider(height: 24),
          const SettingsSection(title: 'Pro'),
          SettingsRow(
            icon: Icons.workspace_premium_outlined,
            title: isPro ? 'Pro active' : 'Upgrade to Pro',
            subtitle: isPro
                ? 'Ads removed · Unlimited batch processing'
                : 'Remove ads and unlock unlimited processing',
            trailing: isPro
                ? const Icon(Icons.verified_outlined, color: Colors.green, size: 20)
                : null,
            onTap: () => context.push('/pro'),
          ),
          if (!isPro)
            SettingsRow(
              icon: Icons.restore_outlined,
              title: 'Restore purchases',
              subtitle: purchaseState.isRestoring
                  ? 'Restoring...'
                  : 'Recover Pro on this device',
              onTap: purchaseState.isRestoring
                  ? null
                  : () => ref.read(purchaseUiProvider.notifier).restore(),
            ),
          const Divider(height: 24),
          const SettingsSection(title: 'Privacy'),
          SettingsRow(
            icon: Icons.offline_bolt_outlined,
            title: 'Offline processing',
            subtitle: 'All tools run on your device',
            trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ),
          SettingsRow(
            icon: Icons.cloud_off_outlined,
            title: 'No cloud uploads',
            subtitle: 'Files never leave your phone',
            trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ),
          SettingsRow(
            icon: Icons.security_outlined,
            title: 'Permissions',
            subtitle: 'Camera, storage, and files',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Permissions are requested only when a tool needs them.'),
                ),
              );
            },
          ),
          SettingsRow(
            icon: Icons.history_outlined,
            title: 'Recent files',
            onTap: () => context.push('/recent-files'),
          ),
          SettingsRow(
            icon: Icons.cached_outlined,
            title: 'Clear processing cache',
            subtitle: 'Free space from temp and enhancement files',
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear cache?'),
                  content: const Text(
                    'This removes temporary and cached enhancement files. '
                    'Your saved PDFs and images are not deleted.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(cacheMaintenanceServiceProvider).clearAllCaches();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined, size: 22),
            title: const Text('Clear recent file history'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear history?'),
                  content: const Text('This removes all recent file entries.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(recentFilesProvider.notifier).clearAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('History cleared')),
                  );
                }
              }
            },
          ),
          const Divider(height: 24),
          const SettingsSection(title: 'About'),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data == null
                  ? '...'
                  : '${snapshot.data!.version} (${snapshot.data!.buildNumber})';
              return SettingsRow(
                icon: Icons.info_outline,
                title: 'App version',
                subtitle: version,
              );
            },
          ),
          SettingsRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => context.push('/privacy'),
          ),
          SettingsRow(
            icon: Icons.description_outlined,
            title: 'Terms of use',
            subtitle: 'App usage terms',
            onTap: () => context.push('/terms'),
          ),
          SettingsRow(
            icon: Icons.star_outline,
            title: 'Rate app',
            onTap: () async {
              final uri = Uri.parse(AppConstants.playStoreUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          SettingsRow(
            icon: Icons.share_outlined,
            title: 'Share app',
            onTap: () => Share.share(
              AppConstants.appName,
            ),
          ),
          SettingsRow(
            icon: Icons.support_agent_outlined,
            title: 'Contact support',
            subtitle: AppConstants.supportEmail,
            onTap: () async {
              final uri = Uri(
                scheme: 'mailto',
                path: AppConstants.supportEmail,
                queryParameters: {
                  'subject': '${AppConstants.appName} support',
                },
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
          SettingsRow(
            icon: Icons.phone_outlined,
            title: 'Support phone',
            subtitle: AppConstants.supportPhone,
            onTap: () async {
              final uri = Uri(scheme: 'tel', path: AppConstants.supportPhone);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: CompanyBranding(style: CompanyBrandingStyle.about),
          ),
        ],
      ),
    );
  }
}
