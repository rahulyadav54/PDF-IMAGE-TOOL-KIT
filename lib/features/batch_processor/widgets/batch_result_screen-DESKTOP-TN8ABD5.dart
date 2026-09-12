import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/file_size_formatter.dart';
import '../../../shared/services/file_actions_service.dart';
import '../../../shared/widgets/completion_ad_trigger.dart';
import '../../../shared/widgets/file_action_buttons.dart';
import '../../../shared/widgets/result_stat_row.dart';
import '../models/batch_result.dart';

class BatchResultScreen extends StatelessWidget {
  const BatchResultScreen({
    super.key,
    required this.result,
    required this.fileActions,
    this.onProcessAnother,
  });

  final BatchRunResult result;
  final FileActionsService fileActions;
  final VoidCallback? onProcessAnother;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isZip = result.hasZip;

    return CompletionAdTrigger(
      child: Scaffold(
        appBar: AppBar(title: const Text('Batch Complete')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(Icons.check_circle_outline, size: 72, color: colors.primary),
              const SizedBox(height: 16),
              Text(
                'Batch Processing Complete',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                result.operationLabel,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              ResultStatRow(label: 'Succeeded', value: '${result.successCount}'),
              if (result.failureCount > 0)
                ResultStatRow(
                  label: 'Failed',
                  value: '${result.failureCount}',
                  valueColor: colors.error,
                ),
              ResultStatRow(
                label: 'Total Output',
                value: FileSizeFormatter.format(result.totalOutputBytes),
              ),
              if (isZip)
                ResultStatRow(label: 'Archive', value: result.primaryFileName),
              if (result.failures.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Failed Files',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                ...result.failures.map(
                  (failure) => Card(
                    child: ListTile(
                      title: Text(failure.fileName),
                      subtitle: Text(failure.errorMessage ?? 'Processing failed.'),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FileActionButtons(
                filePath: result.primaryOutputPath,
                fileActions: fileActions,
                trailing: TextButton(
                  onPressed: onProcessAnother ?? () => context.pop(),
                  child: const Text('Process Another Batch'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
