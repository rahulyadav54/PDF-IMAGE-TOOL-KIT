import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/file_size_formatter.dart';
import '../services/file_actions_service.dart';
import 'completion_ad_trigger.dart';
import 'file_action_buttons.dart';
import 'result_stat_row.dart';

/// Result screen for operations that produce multiple files or a ZIP archive.
class MultiFileResultScreen extends StatelessWidget {
  const MultiFileResultScreen({
    super.key,
    required this.title,
    required this.fileActions,
    required this.primaryOutputPath,
    this.subtitle,
    this.fileCount,
    this.zipFileName,
    this.totalSizeBytes,
    this.onProcessAnother,
  });

  final String title;
  final FileActionsService fileActions;
  final String primaryOutputPath;
  final String? subtitle;
  final int? fileCount;
  final String? zipFileName;
  final int? totalSizeBytes;
  final VoidCallback? onProcessAnother;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CompletionAdTrigger(
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.resultPadding),
            children: [
              Icon(Icons.check_circle_outline, size: 72, color: colors.primary),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 32),
              if (fileCount != null)
                ResultStatRow(label: 'Files Created', value: '$fileCount'),
              if (totalSizeBytes != null)
                ResultStatRow(
                  label: 'Total Size',
                  value: FileSizeFormatter.format(totalSizeBytes!),
                ),
              if (zipFileName != null)
                ResultStatRow(label: 'ZIP Archive', value: zipFileName!),
              const SizedBox(height: 32),
              FileActionButtons(
                filePath: primaryOutputPath,
                fileActions: fileActions,
                trailing: TextButton(
                  onPressed: onProcessAnother ?? () => context.pop(),
                  child: const Text('Process Another'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
