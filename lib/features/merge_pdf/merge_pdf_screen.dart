import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_exception.dart';
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
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/step_bar.dart';
import '../../shared/widgets/result_screen.dart';
import 'models/merge_pdf_item.dart';
import 'providers/merge_session_provider.dart';
import 'services/pdf_merge_service.dart';
import 'widgets/merge_files_list.dart';

class MergePdfScreen extends ConsumerStatefulWidget {
  const MergePdfScreen({super.key});

  @override
  ConsumerState<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends ConsumerState<MergePdfScreen> {
  static const _uuid = Uuid();

  bool _isLoading = false;
  bool _isMerging = false;
  String? _fatalError;
  int _progressCurrent = 0;
  int _progressTotal = 0;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addFiles() async {
    setState(() {
      _fatalError = null;
      _isLoading = true;
    });

    try {
      final fileService = ref.read(fileServiceProvider);
      final paths = await fileService.pickMultipleFiles(allowedExtensions: ['pdf']);

      final validationService = ref.read(pdfValidationServiceProvider);
      final newItems = <MergePdfItem>[];

      for (final path in paths) {
        final validation = await validationService.validate(path);
        newItems.add(
          MergePdfItem(
            id: _uuid.v4(),
            filePath: path,
            fileName: validation.fileName,
            pageCount: validation.pageCount,
            fileSizeBytes: validation.fileSizeBytes,
          ),
        );
      }

      final beforeCount = ref.read(mergeSessionProvider).length;
      ref.read(mergeSessionProvider.notifier).addItems(newItems);
      final afterCount = ref.read(mergeSessionProvider).length;

      if (afterCount == beforeCount && newItems.isNotEmpty) {
        _showMessage('Selected files are already in the list.');
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

  Future<void> _merge() async {
    final items = ref.read(mergeSessionProvider);
    if (items.length < 2) {
      _showMessage('Add at least two PDF files to merge.');
      return;
    }

    setState(() {
      _fatalError = null;
      _isMerging = true;
      _progressCurrent = 0;
      _progressTotal = items.length;
    });

    try {
      final canOperate = await ref.read(entitlementServiceProvider).canPerformOperation();
      if (!canOperate) {
        throw const ProcessingException(
          'Unable to process this file right now. Please try again.',
        );
      }

      final mergeService = ref.read(pdfMergeServiceProvider);
      final result = await mergeService.merge(
        items: items,
        onProgress: (current, total) {
          if (mounted) {
            setState(() {
              _progressCurrent = current;
              _progressTotal = total;
            });
          }
        },
      );

      await ref.read(entitlementServiceProvider).recordOperation();

      final recentService = ref.read(recentFilesServiceProvider);
      final entry = await recentService.createEntry(
        filePath: result.outputPath,
        operation: 'Merge PDF',
        fileSizeBytes: result.fileSizeBytes,
      );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;

      ref.read(mergeSessionProvider.notifier).clear();

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: 'Merge Complete',
            outputPath: result.outputPath,
            fileActions: ref.read(fileActionsServiceProvider),
            subtitle: result.fileName,
            newSizeBytes: result.fileSizeBytes,
            pageCount: result.pageCount,
            conversionLabel: '${result.sourceFileCount} PDFs merged',
            onProcessAnother: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } on AppException catch (e) {
      if (mounted) setState(() => _fatalError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _fatalError = 'Unable to merge PDFs. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isMerging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(mergeSessionProvider);
    final notifier = ref.read(mergeSessionProvider.notifier);
    final colors = Theme.of(context).colorScheme;

    if (_fatalError != null) {
      return Scaffold(
        appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.mergePdf)),
        body: ErrorView(
          message: _fatalError!,
          onRetry: () => setState(() => _fatalError = null),
          onChooseAnother: _addFiles,
          onGoBack: () => Navigator.of(context).pop(),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const ToolAppBarTitle(tool: ToolType.mergePdf),
            actions: [
              if (items.length >= 2)
                TextButton(
                  onPressed: _isMerging ? null : _merge,
                  child: const Text('Merge'),
                ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                StepBar(currentStep: items.isEmpty ? 1 : 2),
                const SizedBox(height: 20),
                Text(
                  items.isEmpty ? 'Select PDFs' : 'Arrange & Merge',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  items.isEmpty
                      ? 'Choose two or more PDF files to combine into one document.'
                      : '${items.length} files • ${notifier.totalPages} pages • ${FileSizeFormatter.format(notifier.totalBytes)}',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                if (items.isEmpty)
                  const EmptyStateCard(
                    icon: Icons.merge_type_outlined,
                    title: 'No files selected',
                    message: 'Add PDFs in the order you want them merged.',
                  )
                else
                  MergeFilesList(
                    items: items,
                    onReorder: notifier.reorder,
                    onRemove: (item) => notifier.remove(item.id),
                  ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isLoading || _isMerging ? null : _addFiles,
                  icon: const Icon(Icons.add_outlined),
                  label: Text(items.isEmpty ? 'Add PDF Files' : 'Add More Files'),
                ),
                if (items.length >= 2) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isMerging ? null : _merge,
                    icon: const Icon(Icons.merge_type_outlined),
                    label: Text('Merge ${items.length} PDFs'),
                  ),
                ] else if (items.length == 1) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Add at least one more PDF to continue.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(message: 'Validating PDFs...'),
        if (_isMerging)
          LoadingOverlay(
            message: 'Merging PDFs...',
            progress: _progressTotal > 0 ? _progressCurrent / _progressTotal : null,
            progressLabel: _progressTotal > 0
                ? 'File $_progressCurrent of $_progressTotal'
                : null,
          ),
      ],
    );
  }
}