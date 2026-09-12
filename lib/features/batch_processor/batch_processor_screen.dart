import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/progress_throttle.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../shared/providers/recent_files_provider.dart';
import '../../shared/services/entitlement_service.dart';
import '../../shared/services/file_actions_service.dart';
import '../../shared/services/file_service.dart';
import '../../shared/services/pdf_validation_service.dart';
import '../../shared/services/recent_files_service.dart';
import '../../shared/widgets/empty_state_card.dart';
import '../../shared/models/tool_type.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/tool_app_bar_title.dart';
import '../../shared/services/bulk_processing/cancel_token.dart';
import '../../shared/services/cache_maintenance_service.dart';
import '../../shared/services/storage_guard_service.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/processing_job_overlay.dart';
import '../../shared/widgets/step_bar.dart';
import '../image_to_pdf/services/image_validation_service.dart';
import 'engine/batch_operation.dart';
import 'engine/batch_operations_registry.dart';
import 'engine/batch_processor_engine.dart';
import 'models/batch_file_item.dart';
import 'models/batch_result.dart';
import 'providers/batch_session_provider.dart';
import 'widgets/batch_config_panel.dart';
import 'widgets/batch_files_list.dart';
import 'widgets/batch_operation_selector.dart';
import 'widgets/batch_result_screen.dart';

class BatchProcessorScreen extends ConsumerStatefulWidget {
  const BatchProcessorScreen({super.key});

  @override
  ConsumerState<BatchProcessorScreen> createState() => _BatchProcessorScreenState();
}

class _BatchProcessorScreenState extends ConsumerState<BatchProcessorScreen> {
  static const _uuid = Uuid();

  bool _isLoading = false;
  bool _isProcessing = false;
  String? _fatalError;
  BatchProgress? _progress;
  CancelToken? _cancelToken;
  final _progressThrottle = ProgressThrottle();

  @override
  void dispose() {
    _progressThrottle.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  BatchOperation? _currentOperation() {
    final session = ref.read(batchSessionProvider);
    for (final operation in ref.read(batchOperationsRegistryProvider)) {
      if (operation.type == session.operationType) return operation;
    }
    return null;
  }

  Future<void> _addFiles() async {
    final session = ref.read(batchSessionProvider);
    setState(() {
      _fatalError = null;
      _isLoading = true;
    });

    try {
      final paths = await ref.read(fileServiceProvider).pickMultipleFiles(
        allowedExtensions: session.operationType.allowedExtensions,
      );

      final items = <BatchFileItem>[];
      if (session.operationType.isImageOperation) {
        final validationService = ref.read(imageValidationServiceProvider);
        for (final path in paths) {
          final validation = await validationService.validate(path);
          items.add(
            BatchFileItem(
              id: _uuid.v4(),
              filePath: path,
              fileName: validation.fileName,
              fileSizeBytes: validation.fileSizeBytes,
            ),
          );
        }
      } else {
        final validationService = ref.read(pdfValidationServiceProvider);
        for (final path in paths) {
          final validation = await validationService.validate(path);
          items.add(
            BatchFileItem(
              id: _uuid.v4(),
              filePath: path,
              fileName: validation.fileName,
              fileSizeBytes: validation.fileSizeBytes,
              pageCount: validation.pageCount,
            ),
          );
        }
      }

      final before = ref.read(batchSessionProvider).files.length;
      final remaining = AppConstants.maxBatchProcessorFiles - before;
      if (remaining <= 0) {
        _showMessage('Maximum ${AppConstants.maxBatchProcessorFiles} files per batch.');
        return;
      }

      final limitedItems = items.take(remaining).toList();
      ref.read(batchSessionProvider.notifier).addFiles(limitedItems);
      final after = ref.read(batchSessionProvider).files.length;

      if (limitedItems.length < items.length) {
        _showMessage(
          'Added ${limitedItems.length} files (limit ${AppConstants.maxBatchProcessorFiles}).',
        );
      } else if (before == after && items.isNotEmpty) {
        _showMessage('Selected files are already in the queue.');
      }
    } on AppException catch (e) {
      if (e is FilePickerCancelledException) return;
      setState(() => _fatalError = e.message);
    } catch (_) {
      setState(() => _fatalError = 'Unable to add files. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processBatch() async {
    final session = ref.read(batchSessionProvider);
    if (session.files.isEmpty) {
      _showMessage('Add at least one file to process.');
      return;
    }

    final canBatch = await ref.read(entitlementServiceProvider).canRunBatch(
      session.files.length,
    );
    if (!canBatch) {
      _showMessage('Add at least one file to process.');
      return;
    }

    final operation = _currentOperation();
    if (operation == null) {
      setState(() => _fatalError = 'This batch operation is not available.');
      return;
    }

    _cancelToken = CancelToken();
    setState(() {
      _fatalError = null;
      _isProcessing = true;
      _progress = BatchProgress(
        current: 0,
        total: session.files.length,
        currentFileName: 'Starting...',
      );
    });

    try {
      final canOperate = await ref.read(entitlementServiceProvider).canPerformOperation();
      if (!canOperate) {
        throw const ProcessingException(
          'Unable to start batch processing. Please try again.',
        );
      }

      await ref.read(storageGuardServiceProvider).ensureSpaceForPaths(
            session.files.map((f) => f.filePath).toList(),
          );

      final result = await ref.read(batchProcessorEngineProvider).run(
        operation: operation,
        items: session.files,
        config: session.config,
        cancelToken: _cancelToken,
        onProgress: (progress) {
          if (!mounted) return;
          _progressThrottle.call(() {
            if (!mounted) return;
            setState(() => _progress = progress);
          });
        },
      );

      await ref.read(entitlementServiceProvider).recordOperation();
      await ref.read(cacheMaintenanceServiceProvider).runAfterHeavyJob();

      final recentService = ref.read(recentFilesServiceProvider);
      final entry = await recentService.createEntry(
        filePath: result.primaryOutputPath,
        operation: 'Batch: ${result.operationLabel}',
        fileSizeBytes: result.totalOutputBytes,
      );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => BatchResultScreen(
            result: result,
            fileActions: ref.read(fileActionsServiceProvider),
            onProcessAnother: () {
              Navigator.of(context).pop();
              ref.read(batchSessionProvider.notifier).clear();
            },
          ),
        ),
      );
    } on BulkCancelledException {
      if (mounted) _showMessage('Batch processing cancelled.');
    } on AppException catch (e) {
      if (mounted) setState(() => _fatalError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _fatalError = 'Batch processing failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _progress = null;
          _cancelToken = null;
        });
      }
    }
  }

  Future<void> _confirmCancel() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel processing?'),
        content: const Text('Completed files are kept. Remaining files will be skipped.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continue')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel')),
        ],
      ),
    );
    if (shouldCancel == true) _cancelToken?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return Scaffold(
        appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.batchProcessor)),
        body: ErrorView(
          message: _fatalError!,
          onRetry: () => setState(() => _fatalError = null),
          onGoBack: () => Navigator.of(context).pop(),
        ),
      );
    }

    final session = ref.watch(batchSessionProvider);
    final colors = Theme.of(context).colorScheme;
    final totalBytes = session.files.fold<int>(0, (sum, f) => sum + f.fileSizeBytes);
    final step = session.files.isEmpty ? 1 : 2;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.batchProcessor)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                StepBar(currentStep: step),
                const SizedBox(height: 20),
                Text(
                  'Choose Operation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                BatchOperationSelector(
                  selected: session.operationType,
                  enabled: !_isProcessing,
                  onChanged: (type) {
                    ref.read(batchSessionProvider.notifier).setOperation(type);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Files (${session.files.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    if (session.files.isNotEmpty)
                      Text(
                        FileSizeFormatter.format(totalBytes),
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (session.files.isEmpty)
                  const EmptyStateCard(
                    icon: Icons.layers_outlined,
                    title: 'No files added',
                    message: 'Add images or PDFs to process them in one batch.',
                  )
                else ...[
                  BatchFilesList(
                    items: session.files,
                    onRemove: (item) {
                      ref.read(batchSessionProvider.notifier).removeFile(item.id);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                OutlinedButton.icon(
                  onPressed: _isLoading || _isProcessing ? null : _addFiles,
                  icon: const Icon(Icons.add_outlined),
                  label: Text(session.files.isEmpty ? 'Add Files' : 'Add More Files'),
                ),
                if (session.files.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Configuration',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  BatchConfigPanel(
                    operationType: session.operationType,
                    config: session.config,
                    enabled: !_isProcessing,
                    onChanged: (config) {
                      ref.read(batchSessionProvider.notifier).setConfig(config);
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : _processBatch,
                    icon: const Icon(Icons.play_arrow_outlined),
                    label: Text('Process ${session.files.length} Files'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(message: 'Validating files...'),
        if (_isProcessing && _progress != null)
          ProcessingJobOverlay(
            title: 'Processing documents',
            completed: _progress!.current,
            total: _progress!.total,
            failed: _progress!.failedCount,
            currentLabel: _progress!.currentFileName,
            onCancel: _confirmCancel,
          ),
      ],
    );
  }
}