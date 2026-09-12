import 'package:flutter/material.dart';
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
import '../../shared/widgets/result_screen.dart';
import '../../shared/widgets/step_bar.dart';
import '../../shared/widgets/tool_app_bar_title.dart';
import 'services/pdf_watermark_service.dart';

class PdfWatermarkScreen extends ConsumerStatefulWidget {
  const PdfWatermarkScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<PdfWatermarkScreen> createState() => _PdfWatermarkScreenState();
}

class _PdfWatermarkScreenState extends ConsumerState<PdfWatermarkScreen> {
  final _textController = TextEditingController(text: 'CONFIDENTIAL');
  double _opacity = 0.25;
  bool _diagonal = true;

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

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String? _selectedPath;
  PdfValidationResult? _validation;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _fatalError;

  Future<void> _pickFile() => _loadFile(
        () => ref.read(fileServiceProvider).pickFile(allowedExtensions: ['pdf']),
      );

  Future<void> _loadFile(Future<String?> Function() load) async {
    setState(() {
      _fatalError = null;
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

  Future<void> _apply() async {
    if (_selectedPath == null || _validation == null) return;
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

      final result = await ref.read(pdfWatermarkServiceProvider).apply(
            inputPath: _selectedPath!,
            options: PdfWatermarkOptions(
              text: _textController.text.trim(),
              opacity: _opacity,
              diagonal: _diagonal,
            ),
            pageCount: _validation!.pageCount,
          );

      await ref.read(entitlementServiceProvider).recordOperation();

      final entry = await ref.read(recentFilesServiceProvider).createEntry(
            filePath: result.outputPath,
            operation: 'PDF Watermark',
            fileSizeBytes: result.outputSizeBytes,
          );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: 'Watermark Applied',
            outputPath: result.outputPath,
            fileActions: ref.read(fileActionsServiceProvider),
            subtitle: result.fileName,
            newSizeBytes: result.outputSizeBytes,
            pageCount: result.pageCount,
            onProcessAnother: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedPath = null;
                _validation = null;
              });
            },
          ),
        ),
      );
    } on AppException catch (e) {
      if (mounted) setState(() => _fatalError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _fatalError = 'Unable to watermark this PDF. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return Scaffold(
        appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.pdfWatermark)),
        body: ErrorView(
          message: _fatalError!,
          onRetry: () => setState(() => _fatalError = null),
          onChooseAnother: _pickFile,
          onGoBack: () => Navigator.of(context).pop(),
        ),
      );
    }

    final step = _selectedPath == null ? 1 : 2;

    return Stack(
      children: [
        Scaffold(
          appBar:
              AppBar(title: const ToolAppBarTitle(tool: ToolType.pdfWatermark)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                StepBar(currentStep: step),
                const SizedBox(height: 20),
                if (_selectedPath == null) ...[
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _pickFile,
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text('Choose PDF'),
                  ),
                ] else ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: Text(_validation!.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${_validation!.pageCount} pages • ${FileSizeFormatter.format(_validation!.fileSizeBytes)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: _isProcessing ? null : _pickFile,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      labelText: 'Watermark text',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Opacity: ${(_opacity * 100).round()}%'),
                  Slider(
                    value: _opacity,
                    min: 0.1,
                    max: 0.6,
                    onChanged: _isProcessing
                        ? null
                        : (v) => setState(() => _opacity = v),
                  ),
                  SwitchListTile(
                    title: const Text('Diagonal watermark'),
                    value: _diagonal,
                    onChanged: _isProcessing
                        ? null
                        : (v) => setState(() => _diagonal = v),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : _apply,
                    icon: const Icon(Icons.water_drop_outlined),
                    label: const Text('Apply Watermark'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(message: 'Validating PDF...'),
        if (_isProcessing) const LoadingOverlay(message: 'Applying watermark...'),
      ],
    );
  }
}
