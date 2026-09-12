import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../shared/providers/app_preferences_provider.dart';
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
import '../../shared/widgets/multi_file_result_screen.dart';
import '../../shared/widgets/result_screen.dart';
import '../split_pdf/utils/page_range_validator.dart';
import 'models/image_export_format.dart';
import 'services/pdf_to_image_service.dart';
import 'widgets/export_format_selector.dart';
import 'widgets/page_selection_panel.dart';

class PdfToImageScreen extends ConsumerStatefulWidget {
  const PdfToImageScreen({super.key});

  @override
  ConsumerState<PdfToImageScreen> createState() => _PdfToImageScreenState();
}

class _PdfToImageScreenState extends ConsumerState<PdfToImageScreen> {
  String? _selectedPath;
  PdfValidationResult? _validation;
  ImageExportFormat? _format;
  PageSelectionMode _selectionMode = PageSelectionMode.allPages;
  bool _isLoading = false;
  bool _isConverting = false;
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

  Future<void> _pickFile() async {
    setState(() {
      _fatalError = null;
      _rangeError = null;
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

  List<int> _resolvePageNumbers() {
    if (_validation == null) return [];

    if (_selectionMode == PageSelectionMode.allPages) {
      return List.generate(_validation!.pageCount, (i) => i + 1);
    }

    final start = int.parse(_startController.text.trim());
    final end = int.parse(_endController.text.trim());
    return List.generate(end - start + 1, (i) => start + i);
  }

  Future<void> _convert() async {
    if (_selectedPath == null || _validation == null) return;

    setState(() {
      _fatalError = null;
      _rangeError = null;
      _isConverting = true;
      _progressCurrent = 0;
      _progressTotal = 0;
    });

    try {
      if (_selectionMode == PageSelectionMode.pageRange) {
        final start = int.tryParse(_startController.text.trim());
        final end = int.tryParse(_endController.text.trim());
        if (start == null || end == null) {
          setState(() {
            _rangeError = 'Enter valid page numbers.';
            _isConverting = false;
          });
          return;
        }

        final validationError =
            PageRangeValidator.validate(start, end, _validation!.pageCount);
        if (validationError != null) {
          setState(() {
            _rangeError = validationError;
            _isConverting = false;
          });
          return;
        }
      }

      final pageNumbers = _resolvePageNumbers();
      setState(() => _progressTotal = pageNumbers.length);

      final canOperate = await ref.read(entitlementServiceProvider).canPerformOperation();
      if (!canOperate) {
        throw const ProcessingException(
          'Unable to process this file right now. Please try again.',
        );
      }

      final service = ref.read(pdfToImageServiceProvider);
      final result = await service.convert(
        inputPath: _selectedPath!,
        pageNumbers: pageNumbers,
        format: _effectiveFormat,
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
        filePath: result.primaryOutputPath,
        operation: 'PDF to Image',
        fileSizeBytes: result.totalOutputBytes,
      );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;

      if (result.hasZip) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (context) => MultiFileResultScreen(
              title: 'Export Complete',
              fileActions: ref.read(fileActionsServiceProvider),
              primaryOutputPath: result.zipPath!,
              subtitle: '${result.pageCount} pages exported as ${_format.label}',
              fileCount: result.pageCount,
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
              title: 'Export Complete',
              outputPath: result.primaryOutputPath,
              fileActions: ref.read(fileActionsServiceProvider),
              subtitle: result.primaryFileName,
              newSizeBytes: result.totalOutputBytes,
              pageCount: result.pageCount,
              conversionLabel: 'PDF → ${_effectiveFormat.label}',
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
        setState(() => _fatalError = 'Unable to export images. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  void _reset() {
    setState(() {
      _selectedPath = null;
      _validation = null;
      _format = null;
      _selectionMode = PageSelectionMode.allPages;
      _rangeError = null;
      _startController.text = '1';
      _endController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return Scaffold(
        appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.pdfToImage)),
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
          appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.pdfToImage)),
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
                    'Choose a PDF to export pages as JPG or PNG images.',
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
                        onPressed: _isConverting ? null : _pickFile,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ExportFormatSelector(
                    selected: _effectiveFormat,
                    onChanged: _isConverting ? (_) {} : (f) => setState(() => _format = f),
                  ),
                  const SizedBox(height: 16),
                  PageSelectionPanel(
                    totalPages: _validation!.pageCount,
                    mode: _selectionMode,
                    onModeChanged: _isConverting
                        ? (_) {}
                        : (mode) => setState(() => _selectionMode = mode),
                    startController: _startController,
                    endController: _endController,
                    rangeError: _rangeError,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isConverting ? null : _convert,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Export Images'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(message: 'Validating PDF...'),
        if (_isConverting)
          LoadingOverlay(
            message: 'Exporting images...',
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
