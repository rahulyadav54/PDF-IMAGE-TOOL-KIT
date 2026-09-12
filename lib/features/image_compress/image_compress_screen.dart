import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/file_size_formatter.dart';
import '../compress_pdf/widgets/size_comparison_card.dart';
import '../image_to_pdf/services/image_validation_service.dart';
import '../../shared/models/image_format.dart';
import '../../shared/providers/app_preferences_provider.dart';
import '../../shared/providers/recent_files_provider.dart';
import '../../shared/utils/workflow_presets.dart';
import '../../shared/services/entitlement_service.dart';
import '../../shared/services/file_actions_service.dart';
import '../../shared/services/file_service.dart';
import '../../shared/services/recent_files_service.dart';
import '../../shared/models/tool_type.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/tool_app_bar_title.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/step_bar.dart';
import '../../shared/widgets/result_screen.dart';
import 'services/image_compress_service.dart';
import 'widgets/quality_slider_card.dart';

class ImageCompressScreen extends ConsumerStatefulWidget {
  const ImageCompressScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<ImageCompressScreen> createState() =>
      _ImageCompressScreenState();
}

class _ImageCompressScreenState extends ConsumerState<ImageCompressScreen> {
  int get _effectiveQuality =>
      _quality ?? ref.read(appPreferencesProvider).imageCompressQuality;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _quality == null) {
        setState(
          () => _quality = ref.read(appPreferencesProvider).imageCompressQuality,
        );
      }
    });
    final initialPath = widget.initialPath;
    if (initialPath != null && initialPath.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadFile(() => Future<String?>.value(initialPath));
      });
    }
  }

  String? _selectedPath;
  ImageValidationResult? _validation;
  ImageFormat? _format;
  int? _quality;
  bool _isLoading = false;
  bool _isCompressing = false;
  String? _fatalError;

  int? get _estimatedBytes {
    if (_validation == null || _format == null) return null;
    return ref.read(imageCompressServiceProvider).estimateSize(
          _validation!.fileSizeBytes,
          _format!,
          _effectiveQuality,
        );
  }

  Future<void> _pickFile() => _loadFile(
        () => ref.read(fileServiceProvider).pickFile(
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
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

      final validation =
          await ref.read(imageValidationServiceProvider).validate(path);
      setState(() {
        _selectedPath = path;
        _validation = validation;
        _format = ImageFormat.fromPath(path);
        _quality = ref.read(appPreferencesProvider).imageCompressQuality;
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
    });

    try {
      final canOperate =
          await ref.read(entitlementServiceProvider).canPerformOperation();
      if (!canOperate) {
        throw const ProcessingException(
          'Unable to process this file right now. Please try again.',
        );
      }

      final result = await ref.read(imageCompressServiceProvider).compress(
            inputPath: _selectedPath!,
            quality: _effectiveQuality,
          );

      await ref.read(entitlementServiceProvider).recordOperation();

      final entry = await ref.read(recentFilesServiceProvider).createEntry(
            filePath: result.outputPath,
            operation: 'Compress Image',
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
            conversionLabel:
                '${result.format.label} at ${result.quality}% quality',
            workflowActions: WorkflowPresets.forImageOutput(),
            onProcessAnother: () {
              Navigator.of(context).pop();
              _reset();
            },
          ),
        ),
      );
    } on AppException catch (e) {
      if (mounted) setState(() => _fatalError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _fatalError = 'Unable to compress this image. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isCompressing = false);
    }
  }

  void _reset() {
    setState(() {
      _selectedPath = null;
      _validation = null;
      _format = null;
      _quality = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return Scaffold(
        appBar:
            AppBar(title: const ToolAppBarTitle(tool: ToolType.imageCompress)),
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
    final supportsQuality = _format?.supportsQuality ?? true;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
              title: const ToolAppBarTitle(tool: ToolType.imageCompress)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                StepBar(currentStep: step),
                const SizedBox(height: 20),
                if (_selectedPath == null) ...[
                  Text(
                    'Select Image',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reduce image file size while keeping it on your device.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _pickFile,
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text('Choose Image'),
                  ),
                ] else ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.image_outlined),
                      title: Text(
                        _validation!.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${_validation!.width}×${_validation!.height} • ${FileSizeFormatter.format(_validation!.fileSizeBytes)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: _isCompressing ? null : _pickFile,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  QualitySliderCard(
                    quality: _effectiveQuality,
                    supportsQuality: supportsQuality,
                    onChanged: _isCompressing
                        ? (_) {}
                        : (value) => setState(() => _quality = value),
                  ),
                  const SizedBox(height: 16),
                  SizeComparisonCard(
                    originalBytes: _validation!.fileSizeBytes,
                    estimatedBytes: _estimatedBytes,
                    showEstimate: true,
                    estimateSubtitle:
                        'Approximate — actual size depends on image content',
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isCompressing ? null : _compress,
                    icon: const Icon(Icons.photo_size_select_small_outlined),
                    label: const Text('Compress Image'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(message: 'Validating image...'),
        if (_isCompressing)
          const LoadingOverlay(message: 'Compressing image...'),
      ],
    );
  }
}
