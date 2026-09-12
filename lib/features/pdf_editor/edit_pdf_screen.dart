import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/tool_type.dart';
import '../../shared/services/file_service.dart';
import '../../shared/services/pdf_validation_service.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/step_bar.dart';
import '../../shared/widgets/tool_app_bar_title.dart';
import 'pdf_editor_workspace_screen.dart';
import 'providers/pdf_editor_session_provider.dart';

class EditPdfScreen extends ConsumerStatefulWidget {
  const EditPdfScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<EditPdfScreen> createState() => _EditPdfScreenState();
}

class _EditPdfScreenState extends ConsumerState<EditPdfScreen> {
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
        () => ref.read(fileServiceProvider).pickFile(
          allowedExtensions: ['pdf'],
        ),
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

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const PdfEditorWorkspaceScreen(),
        ),
      );
    } on AppException catch (e) {
      if (e is FilePickerCancelledException) return;
      setState(() => _fatalError = e.message);
    } catch (_) {
      setState(
          () => _fatalError = 'Unable to open this PDF. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return Scaffold(
        appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.editPdf)),
        body: ErrorView(
          message: _fatalError!,
          onRetry: () => setState(() => _fatalError = null),
          onChooseAnother: _pickFile,
          onGoBack: () => context.pop(),
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.editPdf)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                const StepBar(currentStep: 1),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Edit PDF',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Select a PDF to edit text, images, annotations, signatures, and pages. '
                  'All editing happens privately on your device.',
                  style:
                      TextStyle(color: colors.onSurfaceVariant, height: 1.45),
                ),
                const SizedBox(height: AppSpacing.xxl),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _pickFile,
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('Choose PDF'),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(message: 'Opening PDF editor...'),
      ],
    );
  }
}
