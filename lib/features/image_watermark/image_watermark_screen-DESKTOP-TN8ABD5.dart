import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/file_size_formatter.dart';
import '../image_to_pdf/services/image_validation_service.dart';
import '../../shared/models/tool_type.dart';
import '../../shared/providers/recent_files_provider.dart';
import '../../shared/services/entitlement_service.dart';
import '../../shared/services/file_actions_service.dart';
import '../../shared/services/file_service.dart';
import '../../shared/services/recent_files_service.dart';
import '../../shared/utils/workflow_presets.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/result_screen.dart';
import '../../shared/widgets/step_bar.dart';
import '../../shared/widgets/tool_app_bar_title.dart';
import 'models/watermark_options.dart';
import 'services/image_watermark_service.dart';

class ImageWatermarkScreen extends ConsumerStatefulWidget {
  const ImageWatermarkScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<ImageWatermarkScreen> createState() =>
      _ImageWatermarkScreenState();
}

class _ImageWatermarkScreenState extends ConsumerState<ImageWatermarkScreen> {
  String? _selectedPath;
  ImageValidationResult? _validation;
  WatermarkOptions _options = const WatermarkOptions();
  final _textController = TextEditingController(text: 'CONFIDENTIAL');
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

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() => _loadFile(
        () => ref.read(fileServiceProvider).pickFile(
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
        ),
      );

  Future<void> _pickLogo() async {
    final path = await ref.read(fileServiceProvider).pickFile(
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (path != null) setState(() => _options = _options.copyWith(logoPath: path));
  }

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

  Future<void> _applyWatermark() async {
    if (_selectedPath == null) return;
    setState(() {
      _fatalError = null;
      _isProcessing = true;
    });
    try {
      final canOperate =
          await ref.read(entitlementServiceProvider).canPerformOperation();
      if (!canOperate) {
        throw const ProcessingException(
          'Unable to process this file right now. Please try again.',
        );
      }

      final options = _options.copyWith(text: _textController.text.trim());
      final result = await ref.read(imageWatermarkServiceProvider).apply(
            inputPath: _selectedPath!,
            options: options,
          );
      await ref.read(entitlementServiceProvider).recordOperation();

      final entry = await ref.read(recentFilesServiceProvider).createEntry(
            filePath: result.outputPath,
            operation: 'Image Watermark',
            fileSizeBytes: result.fileSizeBytes,
          );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: 'Watermark Added',
            outputPath: result.outputPath,
            fileActions: ref.read(fileActionsServiceProvider),
            subtitle: result.fileName,
            newSizeBytes: result.fileSizeBytes,
            workflowActions: WorkflowPresets.forImageOutput(),
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
        setState(() => _fatalError = 'Unable to add watermark. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return Scaffold(
        appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.imageWatermark)),
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
          appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.imageWatermark)),
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
                      title: Text(_validation!.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(FileSizeFormatter.format(_validation!.fileSizeBytes)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: _isProcessing ? null : _pickFile,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<WatermarkMode>(
                    segments: WatermarkMode.values
                        .map((m) => ButtonSegment(value: m, label: Text(m.label)))
                        .toList(),
                    selected: {_options.mode},
                    onSelectionChanged: _isProcessing
                        ? null
                        : (value) => setState(() => _options = _options.copyWith(mode: value.first)),
                  ),
                  const SizedBox(height: 16),
                  if (_options.mode == WatermarkMode.text)
                    TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        labelText: 'Watermark text',
                        border: OutlineInputBorder(),
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _pickLogo,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(_options.logoPath == null ? 'Choose logo' : 'Change logo'),
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<WatermarkPosition>(
                    value: _options.position,
                    decoration: const InputDecoration(
                      labelText: 'Position',
                      border: OutlineInputBorder(),
                    ),
                    items: WatermarkPosition.values
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                        .toList(),
                    onChanged: _isProcessing
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _options = _options.copyWith(position: value));
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  Text('Opacity', style: TextStyle(color: colors.onSurfaceVariant)),
                  Slider(
                    value: _options.opacity,
                    min: 0.1,
                    max: 1,
                    divisions: 9,
                    label: '${(_options.opacity * 100).round()}%',
                    onChanged: _isProcessing
                        ? null
                        : (value) => setState(() => _options = _options.copyWith(opacity: value)),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : _applyWatermark,
                    icon: const Icon(Icons.water_drop_outlined),
                    label: const Text('Apply Watermark'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(message: 'Validating image...'),
        if (_isProcessing) const LoadingOverlay(message: 'Applying watermark...'),
      ],
    );
  }
}
