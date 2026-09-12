import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/models/processing_job.dart';
import '../../shared/providers/recent_files_provider.dart';
import '../../shared/services/entitlement_service.dart';
import '../../shared/services/file_actions_service.dart';
import '../../shared/services/file_service.dart';
import '../../shared/services/recent_files_service.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/processing_screen.dart';
import '../../shared/widgets/result_screen.dart';
import '../../shared/services/entitlement_service.dart' show entitlementsProvider;
import 'models/workflow_definition.dart';
import 'models/workflow_operation.dart';
import 'services/workflow_executor.dart';

class WorkflowsScreen extends ConsumerStatefulWidget {
  const WorkflowsScreen({super.key});

  @override
  ConsumerState<WorkflowsScreen> createState() => _WorkflowsScreenState();
}

class _WorkflowsScreenState extends ConsumerState<WorkflowsScreen> {
  ProcessingJob? _job;
  bool _running = false;

  Future<void> _startWorkflow(WorkflowDefinition workflow) async {
    final paths = await _pickInputPaths(workflow.inputType);
    if (paths.isEmpty) return;

    setState(() {
      _running = true;
      _job = ProcessingJob(
        id: workflow.id,
        title: workflow.title,
        type: 'workflow',
        totalItems: workflow.operations.length,
        status: ProcessingStatus.processing,
      );
    });

    try {
      final canOperate = await ref.read(entitlementServiceProvider).canPerformOperation();
      if (!canOperate) throw const ProcessingException('Daily operation limit reached.');

      final result = await ref.read(workflowExecutorProvider).execute(
            workflow: workflow,
            inputPaths: paths,
            onProgress: (step, total, label, itemCurrent, itemTotal) {
              if (!mounted) return;
              setState(() {
                _job = _job?.copyWith(
                  completedItems: step,
                  totalItems: total,
                  currentLabel: '$label ($itemCurrent/$itemTotal)',
                );
              });
            },
          );

      await ref.read(entitlementServiceProvider).recordOperation();

      if (result.failure != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Workflow failed at ${result.failure!.stepLabel}: ${result.failure!.message}',
              ),
            ),
          );
        }
        return;
      }

      final size = await ref.read(fileServiceProvider).getFileSize(result.outputPath);
      final entry = await ref.read(recentFilesServiceProvider).createEntry(
            filePath: result.outputPath,
            operation: workflow.title,
            fileSizeBytes: size,
          );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: 'Workflow Complete',
            outputPath: result.outputPath,
            fileActions: ref.read(fileActionsServiceProvider),
            subtitle: workflow.title,
            newSizeBytes: size,
            onProcessAnother: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
          _job = null;
        });
      }
    }
  }

  Future<List<String>> _pickInputPaths(WorkflowInputType inputType) async {
    switch (inputType) {
      case WorkflowInputType.pdf:
        final path = await ref.read(fileServiceProvider).pickFile(allowedExtensions: ['pdf']);
        return path == null ? [] : [path];
      case WorkflowInputType.images:
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
        );
        return result?.paths.whereType<String>().toList() ?? [];
      case WorkflowInputType.scan:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(entitlementsProvider).valueOrNull?.isPro ?? false;
    final scheme = Theme.of(context).colorScheme;
    final workflows = WorkflowCatalog.all;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Workflows')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                Text('Automated pipelines', style: AppTypography.sectionTitle(context)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Select files and run all steps automatically.',
                  style: AppTypography.cardSubtitle(context),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...workflows.map((workflow) {
                  final locked = workflow.isPro && !isPro;
                  final executable = workflow.operations.isNotEmpty;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Material(
                      color: scheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: locked
                            ? () => context.push('/pro')
                            : executable
                                ? () => _startWorkflow(workflow)
                                : () => context.push(workflow.steps.first.route),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(workflow.icon, color: scheme.primary),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Text(
                                      workflow.title,
                                      style: AppTypography.cardTitle(context),
                                    ),
                                  ),
                                  if (locked)
                                    const Chip(
                                      label: Text('Pro'),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(workflow.description, style: AppTypography.cardSubtitle(context)),
                              const SizedBox(height: AppSpacing.md),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: (executable
                                        ? workflow.operations
                                        : workflow.steps.map(
                                            (s) => WorkflowOperationStep(
                                              operation: WorkflowOperationType.enhance,
                                              label: s.label,
                                            ),
                                          ))
                                    .map(
                                      (step) => Chip(
                                        label: Text(step.label),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    )
                                    .toList(),
                              ),
                              if (executable) ...[
                                const SizedBox(height: AppSpacing.md),
                                FilledButton(
                                  onPressed: locked ? null : () => _startWorkflow(workflow),
                                  child: const Text('Start Workflow'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        if (_running && _job != null) ProcessingScreen(job: _job!),
        if (_running && _job == null) const LoadingOverlay(message: 'Starting workflow...'),
      ],
    );
  }
}
