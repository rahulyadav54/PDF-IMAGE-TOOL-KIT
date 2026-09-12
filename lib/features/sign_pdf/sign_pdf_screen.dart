import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../shared/models/tool_type.dart';
import '../../shared/services/file_service.dart';
import '../../shared/services/pdf_validation_service.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/step_bar.dart';
import '../../shared/widgets/tool_app_bar_title.dart';
import '../pdf_editor/models/editor_models.dart';
import '../pdf_editor/pdf_editor_workspace_screen.dart';
import '../pdf_editor/providers/pdf_editor_session_provider.dart';

/// Fast path to sign a PDF — opens editor with signature tool active.
class SignPdfScreen extends ConsumerStatefulWidget {
  const SignPdfScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<SignPdfScreen> createState() => _SignPdfScreenState();
}

class _SignPdfScreenState extends ConsumerState<SignPdfScreen> {
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

  bool _isLoading = false;
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

      await ref.read(pdfValidationServiceProvider).validate(path);
      final bytes = await File(path).readAsBytes();

      await ref.read(pdfEditorSessionProvider.notifier).loadDocument(
            path: path,
            bytes: bytes,
            fileName: File(path).uri.pathSegments.last,
          );
      ref.read(pdfEditorSessionProvider.notifier).setTool(PdfEditorTool.signature);

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const PdfEditorWorkspaceScreen(signOnlyMode: true),
        ),
      );
    } on AppException catch (e) {
      if (e is FilePickerCancelledException) return;
      setState(() => _fatalError = e.message);
    } catch (_) {
      setState(() => _fatalError = 'Unable to open this PDF. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return Scaffold(
        appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.signPdf)),
        body: ErrorView(
          message: _fatalError!,
          onRetry: () => setState(() => _fatalError = null),
          onChooseAnother: _pickFile,
          onGoBack: () => Navigator.of(context).pop(),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.signPdf)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const StepBar(currentStep: 1),
                const SizedBox(height: 20),
                Text(
                  'Sign PDF',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a PDF, draw your signature, tap to place it, then export and share.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _pickFile,
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('Choose PDF to Sign'),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(message: 'Opening PDF...'),
      ],
    );
  }
}
