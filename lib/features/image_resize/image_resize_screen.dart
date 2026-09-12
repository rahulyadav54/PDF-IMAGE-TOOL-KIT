import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/file_size_formatter.dart';
import '../image_to_pdf/services/image_validation_service.dart';
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
import 'models/resize_mode.dart';
import 'services/image_resize_service.dart';
import 'widgets/resize_config_panel.dart';

class ImageResizeScreen extends ConsumerStatefulWidget {
  const ImageResizeScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<ImageResizeScreen> createState() => _ImageResizeScreenState();
}

class _ImageResizeScreenState extends ConsumerState<ImageResizeScreen> {
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
  ResizeMode _mode = ResizeMode.percentage;
  bool _lockAspectRatio = true;
  ImageOrientation _orientation = ImageOrientation.portrait;
  int _percentage = 50;
  int _targetFileSizeKb = 500;
  bool _isLoading = false;
  bool _isResizing = false;
  String? _fatalError;
  String? _configError;

  final _widthController = TextEditingController();
  final _heightController = TextEditingController();

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() => _loadFile(
        () => ref.read(fileServiceProvider).pickFile(
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
        ),
      );

  Future<void> _loadFile(Future<String?> Function() load) async {
    setState(() {
      _fatalError = null;
      _configError = null;
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
        _widthController.text = validation.width.toString();
        _heightController.text = validation.height.toString();
        _percentage = 50;
        _targetFileSizeKb = 500;
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

  String? _validateConfig() {
    if (_validation == null) return null;

    if (_mode == ResizeMode.dimensions) {
      final width = int.tryParse(_widthController.text.trim());
      final height = int.tryParse(_heightController.text.trim());

      if (width == null && height == null) {
        return 'Enter at least width or height.';
      }
      if (width != null && width < 1) return 'Width must be at least 1 px.';
      if (height != null && height < 1) return 'Height must be at least 1 px.';
      if (width != null && width > 10000) return 'Width is too large.';
      if (height != null && height > 10000) return 'Height is too large.';
    }

    return null;
  }

  ImageResizeRequest _buildRequest() {
    final width = int.tryParse(_widthController.text.trim());
    final height = int.tryParse(_heightController.text.trim());

    return ImageResizeRequest(
      mode: _mode,
      lockAspectRatio: _lockAspectRatio,
      targetWidth: width,
      targetHeight: height,
      percentage: _percentage,
      targetFileSizeKb: _targetFileSizeKb,
      orientation: _orientation,
    );
  }

  Future<void> _resize() async {
    if (_selectedPath == null || _validation == null) return;

    final validationError = _validateConfig();
    if (validationError != null) {
      setState(() => _configError = validationError);
      return;
    }

    setState(() {
      _fatalError = null;
      _configError = null;
      _isResizing = true;
    });

    try {
      final canOperate =
          await ref.read(entitlementServiceProvider).canPerformOperation();
      if (!canOperate) {
        throw const ProcessingException(
          'Unable to process this file right now. Please try again.',
        );
      }

      final result = await ref.read(imageResizeServiceProvider).resize(
            inputPath: _selectedPath!,
            request: _buildRequest(),
          );

      await ref.read(entitlementServiceProvider).recordOperation();

      final entry = await ref.read(recentFilesServiceProvider).createEntry(
            filePath: result.outputPath,
            operation: 'Resize Image',
            fileSizeBytes: result.outputSizeBytes,
          );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: 'Resize Complete',
            outputPath: result.outputPath,
            fileActions: ref.read(fileActionsServiceProvider),
            subtitle: result.fileName,
            originalSizeBytes: result.originalSizeBytes,
            newSizeBytes: result.outputSizeBytes,
            conversionLabel:
                '${result.originalWidth}×${result.originalHeight} → ${result.newWidth}×${result.newHeight}${result.approximateTarget ? ' (approx.)' : ''}',
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
            _fatalError = 'Unable to resize this image. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isResizing = false);
    }
  }

  void _reset() {
    setState(() {
      _selectedPath = null;
      _validation = null;
      _mode = ResizeMode.percentage;
      _lockAspectRatio = true;
      _orientation = ImageOrientation.portrait;
      _percentage = 50;
      _targetFileSizeKb = 500;
      _configError = null;
      _widthController.clear();
      _heightController.clear();
    });
  }

  void _onDimensionChanged() {
    if (!_lockAspectRatio || _validation == null) {
      setState(() => _configError = null);
      return;
    }

    final aspect = _validation!.width / _validation!.height;
    final widthText = _widthController.text.trim();
    final heightText = _heightController.text.trim();

    if (widthText.isNotEmpty && heightText.isEmpty) {
      final width = int.tryParse(widthText);
      if (width != null) {
        _heightController.text = (width / aspect).round().toString();
      }
    } else if (heightText.isNotEmpty && widthText.isEmpty) {
      final height = int.tryParse(heightText);
      if (height != null) {
        _widthController.text = (height * aspect).round().toString();
      }
    }

    setState(() => _configError = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return Scaffold(
        appBar:
            AppBar(title: const ToolAppBarTitle(tool: ToolType.imageResize)),
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
              AppBar(title: const ToolAppBarTitle(tool: ToolType.imageResize)),
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
                    'Change dimensions, scale by percentage, or target an approximate file size.',
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
                        onPressed: _isResizing ? null : _pickFile,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ResizeConfigPanel(
                    mode: _mode,
                    onModeChanged: _isResizing
                        ? (_) {}
                        : (mode) => setState(() {
                              _mode = mode;
                              _configError = null;
                            }),
                    lockAspectRatio: _lockAspectRatio,
                    onLockAspectRatioChanged: _isResizing
                        ? (_) {}
                        : (value) => setState(() => _lockAspectRatio = value),
                    orientation: _orientation,
                    onOrientationChanged: _isResizing
                        ? (_) {}
                        : (value) => setState(() => _orientation = value),
                    widthController: _widthController,
                    heightController: _heightController,
                    onDimensionChanged: _onDimensionChanged,
                    percentage: _percentage,
                    onPercentageChanged: _isResizing
                        ? (_) {}
                        : (value) => setState(() => _percentage = value),
                    targetFileSizeKb: _targetFileSizeKb,
                    onTargetFileSizeChanged: _isResizing
                        ? (_) {}
                        : (value) => setState(() => _targetFileSizeKb = value),
                    originalWidth: _validation!.width,
                    originalHeight: _validation!.height,
                    validationError: _configError,
                    enabled: !_isResizing,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isResizing ? null : _resize,
                    icon: const Icon(Icons.aspect_ratio_outlined),
                    label: const Text('Resize Image'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(message: 'Validating image...'),
        if (_isResizing) const LoadingOverlay(message: 'Resizing image...'),
      ],
    );
  }
}
