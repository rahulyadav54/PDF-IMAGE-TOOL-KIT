import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../shared/models/tool_type.dart';
import '../../shared/providers/recent_files_provider.dart';
import '../../shared/services/entitlement_service.dart';
import '../../shared/services/file_actions_service.dart';
import '../../shared/services/file_service.dart';
import '../../shared/services/pdf_validation_service.dart';
import '../../shared/services/recent_files_service.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/step_bar.dart';
import '../../shared/widgets/tool_app_bar_title.dart';
import 'services/pdf_extract_text_service.dart';

class ExtractTextScreen extends ConsumerStatefulWidget {
  const ExtractTextScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<ExtractTextScreen> createState() => _ExtractTextScreenState();
}

class _ExtractTextScreenState extends ConsumerState<ExtractTextScreen> {
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
  ExtractTextResult? _result;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _fatalError;
  bool _useOcr = true;

  Future<void> _pickFile() => _loadFile(
        () => ref.read(fileServiceProvider).pickFile(allowedExtensions: ['pdf']),
      );

  Future<void> _loadFile(Future<String?> Function() load) async {
    setState(() {
      _fatalError = null;
      _result = null;
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

  Future<void> _extract() async {
    if (_selectedPath == null) return;
    setState(() {
      _fatalError = null;
      _isProcessing = true;
    });
    try {
      final canOperate =
          await ref.read(entitlementServiceProvider).canPerformOperation();
      if (!canOperate) {
        throw const ProcessingException('Daily operation limit reached.');
      }

      final result = await ref.read(pdfExtractTextServiceProvider).extract(
            inputPath: _selectedPath!,
            useOcrFallback: _useOcr,
          );

      await ref.read(entitlementServiceProvider).recordOperation();

      final entry = await ref.read(recentFilesServiceProvider).createEntry(
            filePath: result.outputPath,
            operation: 'Extract Text',
            fileSizeBytes: result.characterCount,
          );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (mounted) setState(() => _result = result);
    } on AppException catch (e) {
      if (mounted) setState(() => _fatalError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _fatalError = 'Unable to extract text. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return Scaffold(
        appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.extractText)),
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
          appBar:
              AppBar(title: const ToolAppBarTitle(tool: ToolType.extractText)),
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
                    'Extract text to copy or save as a .txt file. OCR is used for scanned documents.',
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
                        onPressed: _isProcessing ? null : _pickFile,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Use OCR for scanned PDFs'),
                    subtitle: const Text('Recognize text from images'),
                    value: _useOcr,
                    onChanged: _isProcessing
                        ? null
                        : (v) => setState(() => _useOcr = v),
                  ),
                  if (_result == null) ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isProcessing ? null : _extract,
                      icon: const Icon(Icons.text_snippet_outlined),
                      label: const Text('Extract Text'),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Text(
                      '${_result!.wordCount} words • ${_result!.characterCount} characters'
                      '${_result!.usedOcr ? ' • OCR used' : ''}',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: SingleChildScrollView(
                        child: SelectableText(_result!.text),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Clipboard.setData(
                              ClipboardData(text: _result!.text),
                            ),
                            icon: const Icon(Icons.copy_outlined),
                            label: const Text('Copy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => ref
                                .read(fileActionsServiceProvider)
                                .shareFile(_result!.outputPath),
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('Share .txt'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(message: 'Validating PDF...'),
        if (_isProcessing) const LoadingOverlay(message: 'Extracting text...'),
      ],
    );
  }
}
