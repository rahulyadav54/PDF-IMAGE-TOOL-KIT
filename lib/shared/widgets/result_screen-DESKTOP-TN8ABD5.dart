import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/file_size_formatter.dart';
import '../models/workflow_action.dart';
import '../services/file_actions_service.dart';
import 'completion_ad_trigger.dart';
import 'file_action_buttons.dart';
import 'result_stat_row.dart';

/// Polished result screen for completed tool operations.
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.title,
    required this.outputPath,
    required this.fileActions,
    this.subtitle,
    this.originalSizeBytes,
    this.newSizeBytes,
    this.conversionLabel,
    this.pageCount,
    this.workflowActions,
    this.onProcessAnother,
  });

  final String title;
  final String outputPath;
  final FileActionsService fileActions;
  final String? subtitle;
  final int? originalSizeBytes;
  final int? newSizeBytes;
  final String? conversionLabel;
  final int? pageCount;
  final List<WorkflowAction>? workflowActions;
  final VoidCallback? onProcessAnother;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final savedPercent = originalSizeBytes != null && newSizeBytes != null
        ? FileSizeFormatter.savedPercent(originalSizeBytes!, newSizeBytes!)
        : null;

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
              if (conversionLabel != null)
                ResultStatRow(label: 'Conversion', value: conversionLabel!),
              if (pageCount != null)
                ResultStatRow(label: 'Pages', value: '$pageCount'),
              if (originalSizeBytes != null)
                ResultStatRow(
                  label: 'Original Size',
                  value: FileSizeFormatter.format(originalSizeBytes!),
                ),
              if (newSizeBytes != null)
                ResultStatRow(
                  label: 'New Size',
                  value: FileSizeFormatter.format(newSizeBytes!),
                ),
              if (savedPercent != null)
                ResultStatRow(label: 'Saved', value: '$savedPercent%'),
              if (workflowActions != null && workflowActions!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Next steps',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: workflowActions!.map((action) {
                    return ActionChip(
                      avatar: Icon(action.icon, size: 18),
                      label: Text(action.label),
                      onPressed: () => _handleWorkflow(context, action),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 32),
              FileActionButtons(
                filePath: outputPath,
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

  Future<void> _handleWorkflow(BuildContext context, WorkflowAction action) async {
    if (action.route == '__share__') {
      await fileActions.shareFile(outputPath);
      return;
    }

    if (action.passOutputPath) {
      await context.push(action.route, extra: outputPath);
    } else {
      await context.push(action.route);
    }
  }
}
