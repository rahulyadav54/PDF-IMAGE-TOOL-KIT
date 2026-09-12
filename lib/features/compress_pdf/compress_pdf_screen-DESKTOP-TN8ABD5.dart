import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../shared/providers/app_preferences_provider.dart';
import '../../shared/providers/recent_files_provider.dart';
import '../../shared/utils/workflow_presets.dart';
import '../../shared/services/entitlement_service.dart';
import '../../shared/services/file_actions_service.dart';
import '../../shared/services/file_service.dart';
import '../../shared/services/pdf_validation_service.dart';
import '../../shared/services/recent_files_service.dart';
import '../../shared/models/tool_type.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/tool_app_bar_title.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/result_screen.dart';
import 'models/compression_level.dart';
import 'services/pdf_compression_service.dart';
import 'widgets/compression_level_selector.dart';
import 'widgets/size_comparison_card.dart';

class CompressPdfScreen extends ConsumerStatefulWidget {
  const CompressPdfScreen({super.key});

  @override
  ConsumerState<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

class _CompressPdfScreenState extends ConsumerState<CompressPdfScreen> {
  String? _selectedPath;
  PdfValidationResult? _validation;
  CompressionLevel? _level;
  bool _isLoading = false;
  bool _isCompressing = false;
  String? _fatalError;
  int _progressCurrent = 0;
  int _progressTotal = 0;

  int? get _estimatedBytes {
    if (_validation == null) return null;
    return CompressionLevel.estimateCompressedSize(
      _validation!.fileSizeBytes,
      _effectiveLevel,
    );
  }

  Future<void> _pickFile() async {
    setState(() {
      _fatalError = null;
      _isLoading = true;
    });

    try {
      final fileService = ref.read(fileServiceProvider);
      final path = await fileService.pickFile(allowedExtensions: ['pdf']);
      if (path == null) return;

      final validation = await ref.read(pdfValidationServiceProvider).validate(path);
      setState(() {
        _selectedPath = path;
        _validation = validation;
      });
    } on AppException catch (e) {
      if (e is FilePickerCancelledException) return;
      setState(() => _fatalError = e.message);
    } catch (_) {
      setState(() => _fatalError = 'Unable to select file. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _compress() async {
    if (_selectedPath == null || _validation == null) return;

    setState(() {
      _fatalError = null;
      _isCompressing = true;
      _progressCurrent = 0;
      _progressTotal = _validation!.pageCount;
    });

    try {
      final canOperate = await ref.read(entitlementServiceProvider).canPerformOperation();
      if (!canOperate) {
        throw const ProcessingException(
          'Unable to process this file right now. Please try again.',
        );
      }

      final service = ref.read(pdfCompressionServiceProvider);
      final result = await service.compress(
        inputPath: _selectedPath!,
        level: _effectiveLevel,
        pageCount: _validation!.pageCount,
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
        operation: 'Compress PDF',
        fileSizeBytes: result.compressedSizeBytes,
      );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: 'Compression Complete',
            outputPath: result.outputPath,
            fileActions: ref.read(fileActionsServiceProvider),
            subtitle: result.fileName,
            originalSizeBytes: result.originalSizeBytes,
            newSizeBytes: result.compressedSizeBytes,
            pageCount: result.pageCount,
            workflowActions: WorkflowPresets.forPdfOutput(),
            onProcessAnother: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedPath = null;
                _validation = null;
                _level = null;
              });
            },
          ),
        ),
      );
    } on AppException catch (e) {
      if (mounted) setState(() => _fatalError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _fatalError = 'Unable to compress this PDF. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isCompressing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return Scaffold(
        appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.compressPdf)),
        body: ErrorView(
          message: _fatalError!,
          onRetry: () => setState(() => _fatalError = null),
          onChooseAnother: _pickFile,
          onGoBack: () => Navigator.of(context).pop(),
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;
    final step = _selectedPath == null ? 1 : 2;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.compressPdf)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _StepBar(currentStep: step),
                const SizedBox(height: 20),
                if (_selectedPath == null) ...[
                  Text(
                    'Select PDF',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a PDF file to compress on your device.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _pickFile,
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text('Choose PDF'),
                  ),
                ] else ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: Text(
                        _validation!.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${_validation!.pageCount} pages • ${FileSizeFormatter.format(_validation!.fileSizeBytes)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Choose another file',
                        onPressed: _isCompressing ? null : _pickFile,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Compression Level',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  CompressionLevelSelector(
                    selected: _effectiveLevel,
                    onChanged: _isCompressing
                        ? (_) {}
                        : (level) => setState(() => _level = level),
                  ),
                  const SizedBox(height: 16),
                  SizeComparisonCard(
                    originalBytes: _validation!.fileSizeBytes,
                    estimatedBytes: _estimatedBytes,
                    showEstimate: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _effectiveLevel.useRasterize
                        ? 'Low and Medium levels rasterize pages for stronger compression on scanned or image-heavy PDFs. Text-only PDFs may see limited reduction.'
                        : 'High quality uses stream compression to preserve selectable text and vectors. Best for documents with mostly text.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isCompressing ? null : _compress,
                    icon: const Icon(Icons.compress_outlined),
                    label: const Text('Compress PDF'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(message: 'Validating PDF...'),
        if (_isCompressing)
          LoadingOverlay(
            message: 'Compressing PDF...',
            progress: _progressTotal > 0 ? _progressCurrent / _progressTotal : null,
            progressLabel: _progressTotal > 0
                ? 'Page $_progressCurrent of $_progressTotal'
                : null,
          ),
      ],
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const total = 4;
    return Row(
      children: List.generate(total, (index) {
        final step = index + 1;
        final active = step <= currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < total - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: active ? colors.primary : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
