import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_exception.dart';
import '../../shared/providers/app_preferences_provider.dart';
import '../../shared/providers/recent_files_provider.dart';
import '../../shared/utils/workflow_presets.dart';
import '../../shared/services/bulk_processing/cancel_token.dart';
import '../../shared/services/entitlement_service.dart';
import '../../shared/services/file_actions_service.dart';
import '../../shared/services/file_service.dart';
import '../../shared/services/recent_files_service.dart';
import '../../shared/services/thumbnail_service.dart';
import '../../shared/models/tool_type.dart';
import '../../shared/widgets/bulk_processing_overlay.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/tool_app_bar_title.dart';
import '../../shared/widgets/empty_state_card.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/step_bar.dart';
import '../../shared/widgets/result_screen.dart';
import 'models/image_pdf_processing_options.dart';
import 'models/image_pdf_item.dart';
import 'providers/image_to_pdf_session_provider.dart';
import 'services/image_to_pdf_orchestrator.dart';
import 'widgets/image_pages_list.dart';
import 'widgets/image_pdf_config_panel.dart';
import 'widgets/image_preview_dialog.dart';
import 'widgets/page_config_panel.dart';

class ImageToPdfScreen extends ConsumerStatefulWidget {
  const ImageToPdfScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends ConsumerState<ImageToPdfScreen> {
  static const _uuid = Uuid();

  CancelToken? _cancelToken;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _fatalError;
  String _stage = '';
  int _progressCurrent = 0;
  int _progressTotal = 0;
  String? _progressDetail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prefs = ref.read(appPreferencesProvider);
      ref.read(imageToPdfSessionProvider.notifier).updateProcessingOptions(
        ImagePdfProcessingOptions(quality: prefs.pdfQuality),
      );
      final initialPath = widget.initialPath;
      if (initialPath != null && initialPath.isNotEmpty) {
        _loadImages(() async => [initialPath]);
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addImages() => _loadImages(
        () => ref.read(fileServiceProvider).pickMultipleFiles(
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif', 'heic'],
        ),
      );

  Future<void> _loadImages(Future<List<String>> Function() load) async {
    setState(() {
      _fatalError = null;
      _isLoading = true;
    });

    try {
      final paths = await load();
      final newItems = <ImagePdfItem>[];

      for (final path in paths) {
        final file = File(path);
        if (!await file.exists()) continue;
        final stat = await file.stat();
        newItems.add(
          ImagePdfItem(
            id: _uuid.v4(),
            filePath: path,
            fileName: file.uri.pathSegments.last,
            fileSizeBytes: stat.size,
          ),
        );
      }

      final before = ref.read(imageToPdfSessionProvider).images.length;
      ref.read(imageToPdfSessionProvider.notifier).addImages(newItems);
      final after = ref.read(imageToPdfSessionProvider).images.length;

      if (after == before && newItems.isNotEmpty) {
        _showMessage('Selected images are already in the list.');
      } else if (newItems.isNotEmpty) {
        _generateThumbnailsInBackground(newItems.map((e) => e.filePath).toList());
      }
    } on AppException catch (e) {
      if (e is FilePickerCancelledException) return;
      setState(() => _fatalError = e.message);
    } catch (_) {
      setState(() => _fatalError = 'Unable to add images. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateThumbnailsInBackground(List<String> paths) async {
    final thumbnails = await ref.read(thumbnailServiceProvider).generateThumbnails(
      paths,
    );
    if (!mounted) return;
    ref.read(imageToPdfSessionProvider.notifier).updateThumbnails(thumbnails);
  }

  Future<void> _confirmCancel() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel processing?'),
        content: const Text('Progress will be lost for this batch.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      _cancelToken?.cancel();
    }
  }

  Future<void> _generatePdf() async {
    final session = ref.read(imageToPdfSessionProvider);
    if (session.images.isEmpty) {
      _showMessage('Add at least one image.');
      return;
    }

    if (_isProcessing) return;

    _cancelToken = CancelToken();
    setState(() {
      _fatalError = null;
      _isProcessing = true;
      _stage = 'pdf';
      _progressCurrent = 0;
      _progressTotal = session.images.length;
      _progressDetail = null;
    });

    try {
      final canOperate =
          await ref.read(entitlementServiceProvider).canPerformOperation();
      if (!canOperate) {
        throw const ProcessingException(
          'Unable to process this file right now. Please try again.',
        );
      }

      final orchestrator = ref.read(imageToPdfOrchestratorProvider);
      final result = await orchestrator.run(
        images: session.images,
        config: session.config,
        options: session.processingOptions,
        cancelToken: _cancelToken,
        onStage: ({
          required stage,
          required current,
          required total,
          detail,
        }) {
          if (!mounted) return;
          setState(() {
            _stage = stage;
            _progressCurrent = current;
            _progressTotal = total;
            _progressDetail = detail;
          });
        },
      );

      await ref.read(entitlementServiceProvider).recordOperation();

      final recentService = ref.read(recentFilesServiceProvider);
      final entry = await recentService.createEntry(
        filePath: result.pdfResult.outputPath,
        operation: 'Image to PDF',
        fileSizeBytes: result.pdfResult.fileSizeBytes,
      );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;
      ref.read(imageToPdfSessionProvider.notifier).clear();

      final subtitle = result.enhancedCount > 0
          ? '${result.pdfResult.pageCount} pages • ${result.enhancedCount} enhanced'
          : '${result.pdfResult.pageCount} pages';

      if (result.failedItems.isNotEmpty) {
        _showMessage(
          '${result.pdfResult.pageCount} of ${session.images.length} images processed.',
        );
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: 'PDF Created',
            outputPath: result.pdfResult.outputPath,
            fileActions: ref.read(fileActionsServiceProvider),
            subtitle: subtitle,
            newSizeBytes: result.pdfResult.fileSizeBytes,
            pageCount: result.pdfResult.pageCount,
            conversionLabel: '${result.pdfResult.pageCount} images → PDF',
            workflowActions: WorkflowPresets.forPdfOutput(),
            onProcessAnother: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } on BulkCancelledException {
      if (mounted) _showMessage('Processing cancelled.');
    } on AppException catch (e) {
      if (mounted) setState(() => _fatalError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _fatalError = 'Unable to create PDF. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _cancelToken = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(imageToPdfSessionProvider);
    final notifier = ref.read(imageToPdfSessionProvider.notifier);
    final colors = Theme.of(context).colorScheme;

    if (_fatalError != null) {
      return Scaffold(
        appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.imageToPdf)),
        body: ErrorView(
          message: _fatalError!,
          onRetry: () => setState(() => _fatalError = null),
          onChooseAnother: _addImages,
          onGoBack: () => Navigator.of(context).pop(),
        ),
      );
    }

    final step = session.images.isEmpty ? 1 : 2;
    final showEnhanceSelected =
        session.processingOptions.processingMode ==
            ImagePdfProcessingMode.enhanceSelected;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const ToolAppBarTitle(tool: ToolType.imageToPdf),
            actions: [
              if (session.images.isNotEmpty)
                TextButton(
                  onPressed: _isProcessing ? null : _generatePdf,
                  child: Text(_isProcessing ? 'Processing...' : 'Create PDF'),
                ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                StepBar(currentStep: step),
                const SizedBox(height: 20),
                Text(
                  session.images.isEmpty ? 'Select Images' : 'Create PDF',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  session.images.isEmpty
                      ? 'Choose JPG, PNG, WEBP, or BMP images to convert into a PDF.'
                      : '${session.images.length} image${session.images.length == 1 ? '' : 's'} selected. Configure processing, reorder, or preview.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                if (session.images.isEmpty)
                  const EmptyStateCard(
                    icon: Icons.image_outlined,
                    title: 'No images yet',
                    message: 'Tap below to select images from your device.',
                  )
                else ...[
                  ImagePagesList(
                    images: session.images,
                    onReorder: notifier.reorder,
                    onPreview: (image) =>
                        ImagePreviewDialog.show(context, image),
                    onRemove: (image) => notifier.remove(image.id),
                    showEnhanceToggle: showEnhanceSelected,
                    onToggleEnhance: (image, selected) =>
                        notifier.toggleEnhancementSelection(image.id, selected),
                  ),
                  const SizedBox(height: 16),
                  ImagePdfConfigPanel(
                    options: session.processingOptions,
                    onChanged: notifier.updateProcessingOptions,
                  ),
                  const SizedBox(height: 16),
                  PageConfigPanel(
                    config: session.config,
                    onChanged: notifier.updateConfig,
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isLoading || _isProcessing ? null : _addImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(session.images.isEmpty
                      ? 'Add Images'
                      : 'Add More Images'),
                ),
                if (session.images.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : _generatePdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(
                      _isProcessing
                          ? 'Processing...'
                          : 'Create PDF (${session.images.length} pages)',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(message: 'Importing images...'),
        if (_isProcessing)
          BulkProcessingOverlay(
            title: _stage == 'enhance' ? 'Enhancing images' : 'Creating your PDF',
            message: _stage == 'enhance'
                ? 'Improving text clarity...'
                : 'Creating PDF...',
            progress: _progressTotal > 0
                ? _progressCurrent / _progressTotal
                : null,
            progressLabel: _progressTotal > 0
                ? '${_progressCurrent} / $_progressTotal'
                : null,
            detail: _progressDetail,
            onCancel: _confirmCancel,
          ),
      ],
    );
  }
}
