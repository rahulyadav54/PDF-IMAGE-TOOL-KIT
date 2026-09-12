import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/tool_type.dart';
import '../../shared/providers/recent_files_provider.dart';
import '../../shared/services/entitlement_service.dart';
import '../../shared/services/file_actions_service.dart';
import '../../shared/services/file_service.dart';
import '../../shared/services/recent_files_service.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/result_screen.dart';
import '../../shared/widgets/step_bar.dart';
import '../../shared/widgets/tool_app_bar_title.dart';
import '../scan_to_pdf/models/scan_enhance_kind.dart';
import '../scan_to_pdf/services/image_enhancement_service.dart';
import '../scan_to_pdf/services/scan_quality_service.dart';
import '../scan_to_pdf/widgets/scan_quality_card.dart';

class CleanDocumentScreen extends ConsumerStatefulWidget {
  const CleanDocumentScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<CleanDocumentScreen> createState() =>
      _CleanDocumentScreenState();
}

class _CleanDocumentScreenState extends ConsumerState<CleanDocumentScreen> {
  String? _sourcePath;
  String? _previewPath;
  ScanQualityReport? _quality;
  ScanEnhanceKind _mode = ScanEnhanceKind.auto;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _fatalError;

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

  Future<void> _pickFile() => _loadFile(
        () => ref.read(fileServiceProvider).pickFile(
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
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
      if (!await File(path).exists()) {
        throw const InvalidFileException('File no longer exists.');
      }

      final quality =
          await ref.read(scanQualityServiceProvider).analyze(path);
      final preview = await ref.read(imageEnhancementServiceProvider).applyEnhancements(
            sourcePath: path,
            kind: ScanEnhanceKind.auto,
            maxDimension: AppConstants.enhancementPreviewMaxDimension,
            jpegQuality: 75,
            preview: true,
            useCache: false,
          );

      setState(() {
        _sourcePath = path;
        _previewPath = preview;
        _quality = quality;
        _mode = ScanEnhanceKind.auto;
      });
    } on AppException catch (e) {
      if (e is FilePickerCancelledException) return;
      setState(() => _fatalError = e.message);
    } catch (_) {
      setState(() => _fatalError = 'Unable to open this image. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePreview(ScanEnhanceKind kind) async {
    if (_sourcePath == null) return;
    setState(() {
      _mode = kind;
      _isProcessing = true;
    });
    try {
      final preview = await ref.read(imageEnhancementServiceProvider).applyEnhancements(
            sourcePath: _sourcePath!,
            kind: kind,
            maxDimension: AppConstants.enhancementPreviewMaxDimension,
            jpegQuality: 75,
            preview: true,
            useCache: false,
          );
      if (mounted) setState(() => _previewPath = preview);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _cleanAndSave() async {
    if (_sourcePath == null) return;
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

      final output = await ref.read(imageEnhancementServiceProvider).applyEnhancements(
            sourcePath: _sourcePath!,
            kind: _mode,
            maxDimension: 2400,
            jpegQuality: 90,
            preview: false,
          );

      await ref.read(entitlementServiceProvider).recordOperation();

      final size = await ref.read(fileServiceProvider).getFileSize(output);
      final entry = await ref.read(recentFilesServiceProvider).createEntry(
            filePath: output,
            operation: 'Clean Document',
            fileSizeBytes: size,
          );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: 'Document Cleaned',
            outputPath: output,
            fileActions: ref.read(fileActionsServiceProvider),
            subtitle: ref.read(fileServiceProvider).getFileName(output),
            newSizeBytes: size,
            onProcessAnother: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } on AppException catch (e) {
      if (mounted) setState(() => _fatalError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _fatalError = 'Unable to clean this image. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return Scaffold(
        appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.cleanDocument)),
        body: ErrorView(
          message: _fatalError!,
          onRetry: () => setState(() => _fatalError = null),
          onChooseAnother: _pickFile,
          onGoBack: () => Navigator.of(context).pop(),
        ),
      );
    }

    final step = _sourcePath == null ? 1 : 2;

    return Stack(
      children: [
        Scaffold(
          appBar:
              AppBar(title: const ToolAppBarTitle(tool: ToolType.cleanDocument)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                StepBar(currentStep: step),
                const SizedBox(height: AppSpacing.lg),
                if (_sourcePath == null) ...[
                  Text(
                    'Clean Document',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Turn a photo of paper into a professional-looking document. '
                    'Preview uses a fast low-res pass; final output is full quality.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _pickFile,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose Photo'),
                  ),
                ] else ...[
                  if (_quality != null) ScanQualityCard(report: _quality!),
                  const SizedBox(height: AppSpacing.md),
                  if (_previewPath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_previewPath!),
                        fit: BoxFit.contain,
                        height: 280,
                        width: double.infinity,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ChoiceChip(
                        label: const Text('Auto'),
                        selected: _mode == ScanEnhanceKind.auto,
                        onSelected: (_) => _updatePreview(ScanEnhanceKind.auto),
                      ),
                      ChoiceChip(
                        label: const Text('Document'),
                        selected: _mode == ScanEnhanceKind.document,
                        onSelected: (_) =>
                            _updatePreview(ScanEnhanceKind.document),
                      ),
                      ChoiceChip(
                        label: const Text('Magic Color'),
                        selected: _mode == ScanEnhanceKind.magicColor,
                        onSelected: (_) =>
                            _updatePreview(ScanEnhanceKind.magicColor),
                      ),
                      ChoiceChip(
                        label: const Text('B&W'),
                        selected: _mode == ScanEnhanceKind.blackWhite,
                        onSelected: (_) =>
                            _updatePreview(ScanEnhanceKind.blackWhite),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : _cleanAndSave,
                    icon: const Icon(Icons.auto_fix_high_outlined),
                    label: const Text('Clean Document'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(message: 'Analyzing image...'),
        if (_isProcessing && _sourcePath != null)
          const LoadingOverlay(message: 'Processing...'),
      ],
    );
  }
}
