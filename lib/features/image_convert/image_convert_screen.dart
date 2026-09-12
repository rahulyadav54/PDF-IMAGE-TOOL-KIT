import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/file_size_formatter.dart';
import '../image_to_pdf/services/image_validation_service.dart';
import '../../shared/models/image_format.dart';
import '../../shared/providers/recent_files_provider.dart';
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
import 'services/image_convert_service.dart';
import 'widgets/image_format_selector.dart';

class ImageConvertScreen extends ConsumerStatefulWidget {
  const ImageConvertScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<ImageConvertScreen> createState() => _ImageConvertScreenState();
}

class _ImageConvertScreenState extends ConsumerState<ImageConvertScreen> {
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
  ImageValidationResult? _validation;
  ImageFormat? _sourceFormat;
  ImageFormat _targetFormat = ImageFormat.png;
  bool _isLoading = false;
  bool _isConverting = false;
  String? _fatalError;

  Future<void> _pickFile() => _loadFile(
        () => ref.read(fileServiceProvider).pickFile(
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'],
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
      final source = ImageFormat.fromPath(path);
      setState(() {
        _selectedPath = path;
        _validation = validation;
        _sourceFormat = source;
        _targetFormat = _defaultTarget(source);
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

  ImageFormat _defaultTarget(ImageFormat? source) {
    if (source == null || source == ImageFormat.png) {
      return ImageFormat.jpg;
    }
    return ImageFormat.png;
  }

  Future<void> _convert() async {
    if (_selectedPath == null || _validation == null || _sourceFormat == null)
      return;

    if (_sourceFormat == _targetFormat) {
      setState(
          () => _fatalError = 'Choose a different output format to convert.');
      return;
    }

    setState(() {
      _fatalError = null;
      _isConverting = true;
    });

    try {
      final canOperate =
          await ref.read(entitlementServiceProvider).canPerformOperation();
      if (!canOperate) {
        throw const ProcessingException(
          'Unable to process this file right now. Please try again.',
        );
      }

      final result = await ref.read(imageConvertServiceProvider).convert(
            inputPath: _selectedPath!,
            targetFormat: _targetFormat,
          );

      await ref.read(entitlementServiceProvider).recordOperation();

      final entry = await ref.read(recentFilesServiceProvider).createEntry(
            filePath: result.outputPath,
            operation: 'Convert Format',
            fileSizeBytes: result.outputSizeBytes,
          );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: 'Conversion Complete',
            outputPath: result.outputPath,
            fileActions: ref.read(fileActionsServiceProvider),
            subtitle: result.fileName,
            originalSizeBytes: result.originalSizeBytes,
            newSizeBytes: result.outputSizeBytes,
            conversionLabel:
                '${result.sourceFormat.label} → ${result.targetFormat.label}',
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
            _fatalError = 'Unable to convert this image. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  void _reset() {
    setState(() {
      _selectedPath = null;
      _validation = null;
      _sourceFormat = null;
      _targetFormat = ImageFormat.png;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return Scaffold(
        appBar:
            AppBar(title: const ToolAppBarTitle(tool: ToolType.imageConvert)),
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
              AppBar(title: const ToolAppBarTitle(tool: ToolType.imageConvert)),
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
                    'Convert JPG, PNG, WEBP, BMP, or GIF to another image format.',
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
                        '${_validation!.width}×${_validation!.height} • ${_sourceFormat?.label ?? 'Image'} • ${FileSizeFormatter.format(_validation!.fileSizeBytes)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: _isConverting ? null : _pickFile,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ImageFormatSelector(
                    selected: _targetFormat,
                    exclude: _sourceFormat,
                    onChanged: _isConverting
                        ? (_) {}
                        : (format) => setState(() => _targetFormat = format),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isConverting ? null : _convert,
                    icon: const Icon(Icons.transform_outlined),
                    label: const Text('Convert Image'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(message: 'Validating image...'),
        if (_isConverting) const LoadingOverlay(message: 'Converting image...'),
      ],
    );
  }
}
