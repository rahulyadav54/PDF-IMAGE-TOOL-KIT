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
import 'services/pdf_unlock_service.dart';

class UnlockPdfScreen extends ConsumerStatefulWidget {
  const UnlockPdfScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<UnlockPdfScreen> createState() => _UnlockPdfScreenState();
}

class _UnlockPdfScreenState extends ConsumerState<UnlockPdfScreen> {
  final _passwordController = TextEditingController();

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
    _passwordController.dispose();
    super.dispose();
  }

  String? _selectedPath;
  PdfValidationResult? _validation;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _fatalError;
  String? _formError;
  bool _obscurePassword = true;

  Future<void> _pickFile() => _loadFile(
        () => ref.read(fileServiceProvider).pickFile(allowedExtensions: ['pdf']),
      );

  Future<void> _loadFile(Future<String?> Function() load) async {
    setState(() {
      _fatalError = null;
      _formError = null;
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
        _passwordController.clear();
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

  Future<void> _unlock() async {
    if (_selectedPath == null || _validation == null) return;
    if (_passwordController.text.isEmpty) {
      setState(() => _formError = 'Enter the PDF password.');
      return;
    }

    setState(() {
      _fatalError = null;
      _formError = null;
      _isProcessing = true;
    });
    try {
      final canOperate =
          await ref.read(entitlementServiceProvider).canPerformOperation();
      if (!canOperate) {
        throw const ProcessingException('Daily operation limit reached.');
      }

      final result = await ref.read(pdfUnlockServiceProvider).unlock(
            inputPath: _selectedPath!,
            password: _passwordController.text,
            pageCount: _validation!.pageCount,
          );

      await ref.read(entitlementServiceProvider).recordOperation();

      final entry = await ref.read(recentFilesServiceProvider).createEntry(
            filePath: result.outputPath,
            operation: 'Unlock PDF',
            fileSizeBytes: result.outputSizeBytes,
          );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: 'PDF Unlocked',
            outputPath: result.outputPath,
            fileActions: ref.read(fileActionsServiceProvider),
            subtitle: result.fileName,
            newSizeBytes: result.outputSizeBytes,
            pageCount: result.pageCount,
            conversionLabel: 'Password removed',
            onProcessAnother: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedPath = null;
                _validation = null;
                _passwordController.clear();
              });
            },
          ),
        ),
      );
    } on AppException catch (e) {
      if (mounted) setState(() => _fatalError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _fatalError = 'Unable to unlock this PDF. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return Scaffold(
        appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.unlockPdf)),
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
          appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.unlockPdf)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                StepBar(currentStep: step),
                const SizedBox(height: 20),
                if (_selectedPath == null) ...[
                  Text(
                    'You must know the password to unlock a protected PDF.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _pickFile,
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text('Choose Protected PDF'),
                  ),
                ] else ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.lock_outlined),
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
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'PDF password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  if (_formError != null) ...[
                    const SizedBox(height: 12),
                    Text(_formError!, style: TextStyle(color: colors.error)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : _unlock,
                    icon: const Icon(Icons.lock_open_outlined),
                    label: const Text('Unlock PDF'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(message: 'Validating PDF...'),
        if (_isProcessing) const LoadingOverlay(message: 'Unlocking PDF...'),
      ],
    );
  }
}
