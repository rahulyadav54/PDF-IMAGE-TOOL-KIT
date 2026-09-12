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
import '../../shared/widgets/step_bar.dart';
import '../../shared/widgets/multi_file_result_screen.dart';
import '../../shared/widgets/result_screen.dart';
import 'models/split_mode.dart';
import 'services/pdf_split_service.dart';
import 'utils/page_range_validator.dart';
import 'widgets/page_range_input.dart';
import 'widgets/split_mode_selector.dart';

class SplitPdfScreen extends ConsumerStatefulWidget {
  const SplitPdfScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends ConsumerState<SplitPdfScreen> {
  @override
  void initState() {
    super.initState();
    final initialPath = widget.initialPath;
    if (initialPath != null && initialPath.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadFile(() => Future<String?>.value(initialPath));
      });
    }
  }

  String? _selectedPath;
  PdfValidationResult? _validation;
  SplitMode _mode = SplitMode.extractRange;
  bool _isLoading = false;
  bool _isSplitting = false;
  String? _fatalError;
  String? _rangeError;
  int _progressCurrent = 0;
  int _progressTotal = 0;

  final _startController = TextEditingController(text: '1');
  final _endController = TextEditingController();

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() => _loadFile(
        () => ref.read(fileServiceProvider).pickFile(
          allowedExtensions: ['pdf'],
        ),
      );

  Future<void> _loadFile(Future<String?> Function() load) async {
    setState(() {
      _fatalError = null;
      _rangeError = null;
      _isLoading = true;
    });

    try {
      final path = await load();
      if (path == null) return;

      final validation =
          await ref.read(pdfValidationServiceProvider).validate(path);
      setState(() {
        _selectedPath = path;
        _validation = validation;
        _startController.text = '1';
        _endController.text = validation.pageCount.toString();
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

  Future<void> _split() async {
    if (_selectedPath == null || _validation == null) return;

    setState(() {
      _fatalError = null;
      _rangeError = null;
      _isSplitting = true;
      _progressCurrent = 0;
      _progressTotal = 0;
    });

    try {
      final canOperate =
          await ref.read(entitlementServiceProvider).canPerformOperation();
      if (!canOperate) {
        throw const ProcessingException(
          'Unable to process this file right now. Please try again.',
        );
      }

      final splitService = ref.read(pdfSplitServiceProvider);
      PdfSplitResult result;

      int? extractedStart;
      int? extractedEnd;

      if (_mode == SplitMode.extractRange) {
        final start = int.tryParse(_startController.text.trim());
        final end = int.tryParse(_endController.text.trim());
        extractedStart = start;
        extractedEnd = end;
        if (start == null || end == null) {
          setState(() {
            _rangeError = 'Enter valid page numbers.';
            _isSplitting = false;
          });
          return;
        }

        final validationError =
            PageRangeValidator.validate(start, end, _validation!.pageCount);
        if (validationError != null) {
          setState(() {
            _rangeError = validationError;
            _isSplitting = false;
          });
          return;
        }

        result = await splitService.extractRange(
          inputPath: _selectedPath!,
          startPage: start,
          endPage: end,
          totalPages: _validation!.pageCount,
          onProgress: (current, total) {
            if (mounted) {
              setState(() {
                _progressCurrent = current;
                _progressTotal = total;
              });
            }
          },
        );
      } else {
        result = await splitService.splitEveryPage(
          inputPath: _selectedPath!,
          totalPages: _validation!.pageCount,
          onProgress: (current, total) {
            if (mounted) {
              setState(() {
                _progressCurrent = current;
                _progressTotal = total;
              });
            }
          },
        );
      }

      await ref.read(entitlementServiceProvider).recordOperation();

      final recentService = ref.read(recentFilesServiceProvider);
      final entry = await recentService.createEntry(
        filePath: result.primaryOutputPath,
        operation: 'Split PDF',
        fileSizeBytes: result.totalOutputBytes,
      );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;

      if (result.hasZip) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (context) => MultiFileResultScreen(
              title: 'Split Complete',
              fileActions: ref.read(fileActionsServiceProvider),
              primaryOutputPath: result.zipPath!,
              subtitle: '${result.fileCount} PDFs created and packaged',
              fileCount: result.fileCount,
              zipFileName: result.zipFileName,
              totalSizeBytes: result.totalOutputBytes,
              onProcessAnother: () {
                Navigator.of(context).pop();
                _reset();
              },
            ),
          ),
        );
      } else {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              title: 'Extraction Complete',
              outputPath: result.primaryOutputPath,
              fileActions: ref.read(fileActionsServiceProvider),
              subtitle: result.primaryFileName,
              newSizeBytes: result.totalOutputBytes,
              pageCount: extractedStart != null && extractedEnd != null
                  ? PageRangeValidator.toPageIndices(
                          extractedStart, extractedEnd)
                      .length
                  : null,
              onProcessAnother: () {
                Navigator.of(context).pop();
                _reset();
              },
            ),
          ),
        );
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _fatalError = e.message);
    } catch (_) {
      if (mounted) {
        setState(
            () => _fatalError = 'Unable to split this PDF. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSplitting = false);
    }
  }

  void _reset() {
    setState(() {
      _selectedPath = null;
      _validation = null;
      _mode = SplitMode.extractRange;
      _rangeError = null;
      _startController.text = '1';
      _endController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return Scaffold(
        appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.splitPdf)),
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
          appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.splitPdf)),
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
                    'Choose a PDF to extract pages from or split into separate files.',
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
                        onPressed: _isSplitting ? null : _pickFile,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Split Mode',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SplitModeSelector(
                    selected: _mode,
                    onChanged: _isSplitting
                        ? (_) {}
                        : (mode) => setState(() => _mode = mode),
                  ),
                  if (_mode == SplitMode.extractRange) ...[
                    const SizedBox(height: 8),
                    PageRangeInput(
                      totalPages: _validation!.pageCount,
                      startController: _startController,
                      endController: _endController,
                      errorText: _rangeError,
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Each of the ${_validation!.pageCount} pages will be saved as a separate PDF and bundled into a ZIP file for easy sharing.',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isSplitting ? null : _split,
                    icon: const Icon(Icons.content_cut_outlined),
                    label: Text(
                      _mode == SplitMode.extractRange
                          ? 'Extract Pages'
                          : 'Split All Pages',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(message: 'Validating PDF...'),
        if (_isSplitting)
          LoadingOverlay(
            message: 'Splitting PDF...',
            progress:
                _progressTotal > 0 ? _progressCurrent / _progressTotal : null,
            progressLabel: _progressTotal > 0
                ? _mode == SplitMode.splitEveryPage
                    ? 'Page $_progressCurrent of $_progressTotal'
                    : 'Processing...'
                : null,
          ),
      ],
    );
  }
}
