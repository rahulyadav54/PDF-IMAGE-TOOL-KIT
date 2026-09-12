import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../shared/providers/recent_files_provider.dart';
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
import '../../shared/widgets/step_bar.dart';
import 'models/editable_pdf_page.dart';
import 'services/pdf_page_editor_service.dart';

class PdfPageEditorScreen extends ConsumerStatefulWidget {
  const PdfPageEditorScreen({super.key});

  @override
  ConsumerState<PdfPageEditorScreen> createState() => _PdfPageEditorScreenState();
}

class _PdfPageEditorScreenState extends ConsumerState<PdfPageEditorScreen> {
  String? _selectedPath;
  PdfValidationResult? _validation;
  List<EditablePdfPage> _pages = [];
  bool _isLoading = false;
  bool _isExporting = false;
  String? _fatalError;
  int _progressCurrent = 0;
  int _progressTotal = 0;

  Future<void> _pickFile() async {
    setState(() {
      _fatalError = null;
      _isLoading = true;
    });

    try {
      final path = await ref.read(fileServiceProvider).pickFile(allowedExtensions: ['pdf']);
      if (path == null) return;

      final validation = await ref.read(pdfValidationServiceProvider).validate(path);
      final pages = ref.read(pdfPageEditorServiceProvider).createInitialPages(validation.pageCount);

      setState(() {
        _selectedPath = path;
        _validation = validation;
        _pages = pages;
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

  void _rotatePage(int index) {
    setState(() => _pages[index].rotateClockwise());
  }

  void _deletePage(int index) {
    if (_pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A PDF must have at least one page.')),
      );
      return;
    }
    setState(() => _pages.removeAt(index));
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final page = _pages.removeAt(oldIndex);
      _pages.insert(newIndex, page);
    });
  }

  Future<void> _export() async {
    if (_selectedPath == null || _validation == null || _pages.isEmpty) return;

    setState(() {
      _fatalError = null;
      _isExporting = true;
      _progressCurrent = 0;
      _progressTotal = _pages.length;
    });

    try {
      final canOperate = await ref.read(entitlementServiceProvider).canPerformOperation();
      if (!canOperate) {
        throw const ProcessingException('Daily operation limit reached.');
      }

      final result = await ref.read(pdfPageEditorServiceProvider).export(
            inputPath: _selectedPath!,
            pages: List.of(_pages),
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

      final entry = await ref.read(recentFilesServiceProvider).createEntry(
            filePath: result.outputPath,
            operation: 'Rotate & Reorder PDF',
            fileSizeBytes: result.outputSizeBytes,
          );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: 'PDF Updated',
            outputPath: result.outputPath,
            fileActions: ref.read(fileActionsServiceProvider),
            subtitle: result.fileName,
            newSizeBytes: result.outputSizeBytes,
            pageCount: result.pageCount,
            conversionLabel: 'Pages reordered & rotated',
            onProcessAnother: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedPath = null;
                _validation = null;
                _pages = [];
              });
            },
          ),
        ),
      );
    } on AppException catch (e) {
      if (mounted) setState(() => _fatalError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _fatalError = 'Unable to update this PDF. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return Scaffold(
        appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.pdfPageEditor)),
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
          appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.pdfPageEditor)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                StepBar(currentStep: step),
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
                    'Drag to reorder pages, rotate upside-down scans, or remove unwanted pages.',
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
                        '${_pages.length} pages • ${FileSizeFormatter.format(_validation!.fileSizeBytes)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Choose another file',
                        onPressed: _isExporting ? null : _pickFile,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Drag the handle to reorder. Tap rotate or delete on each page.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _pages.length,
                    onReorder: _isExporting ? (_, __) {} : _onReorder,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return Card(
                        key: ValueKey('${page.originalIndex}_${index}_${page.rotationSteps}'),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                          title: Text('Page ${page.displayPageNumber}'),
                          subtitle: Text(
                            page.rotationSteps == 0
                                ? 'No rotation'
                                : 'Rotated ${page.rotationSteps * 90}°',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.rotate_right_outlined),
                                tooltip: 'Rotate 90°',
                                onPressed: _isExporting ? null : () => _rotatePage(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Remove page',
                                onPressed: _isExporting ? null : () => _deletePage(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isExporting ? null : _export,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save PDF'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(message: 'Validating PDF...'),
        if (_isExporting)
          LoadingOverlay(
            message: 'Saving PDF...',
            progress: _progressTotal > 0 ? _progressCurrent / _progressTotal : null,
            progressLabel: _progressTotal > 0
                ? 'Page $_progressCurrent of $_progressTotal'
                : null,
          ),
      ],
    );
  }
}
