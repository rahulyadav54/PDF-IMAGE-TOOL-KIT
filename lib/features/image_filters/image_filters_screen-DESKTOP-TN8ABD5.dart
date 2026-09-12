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
import 'models/filter_options.dart';
import 'services/image_filter_service.dart';

class ImageFiltersScreen extends ConsumerStatefulWidget {
  const ImageFiltersScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<ImageFiltersScreen> createState() => _ImageFiltersScreenState();
}

class _ImageFiltersScreenState extends ConsumerState<ImageFiltersScreen> {
  String? _selectedPath;
  ImageValidationResult? _validation;
  FilterOptions _options = const FilterOptions();
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

  Future<void> _applyFilters() async {
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

      final result = await ref.read(imageFilterServiceProvider).apply(
            inputPath: _selectedPath!,
            options: _options,
          );
      await ref.read(entitlementServiceProvider).recordOperation();

      final entry = await ref.read(recentFilesServiceProvider).createEntry(
            filePath: result.outputPath,
            operation: 'Image Filters',
            fileSizeBytes: result.fileSizeBytes,
          );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: 'Filters Applied',
            outputPath: result.outputPath,
            fileActions: ref.read(fileActionsServiceProvider),
            subtitle: result.fileName,
            newSizeBytes: result.fileSizeBytes,
            conversionLabel: _options.preset.label,
            workflowActions: WorkflowPresets.forImageOutput(),
            onProcessAnother: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedPath = null;
                _validation = null;
                _options = const FilterOptions();
              });
            },
          ),
        ),
      );
    } on AppException catch (e) {
      if (mounted) setState(() => _fatalError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _fatalError = 'Unable to apply filters. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _slider(
    String label,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value.toDouble(),
          min: -100,
          max: 100,
          divisions: 40,
          label: '$value',
          onChanged: _isProcessing ? null : (v) => onChanged(v.round()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return Scaffold(
        appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.imageFilters)),
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
          appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.imageFilters)),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: FilterPreset.values.map((preset) {
                      final selected = _options.preset == preset;
                      return ChoiceChip(
                        label: Text(preset.label),
                        selected: selected,
                        onSelected: _isProcessing
                            ? null
                            : (_) => setState(() => _options = _options.copyWith(preset: preset)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _slider('Brightness', _options.brightness, (v) {
                    setState(() => _options = _options.copyWith(brightness: v));
                  }),
                  _slider('Contrast', _options.contrast, (v) {
                    setState(() => _options = _options.copyWith(contrast: v));
                  }),
                  _slider('Saturation', _options.saturation, (v) {
                    setState(() => _options = _options.copyWith(saturation: v));
                  }),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : _applyFilters,
                    icon: const Icon(Icons.tune_outlined),
                    label: const Text('Apply Filters'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(message: 'Validating image...'),
        if (_isProcessing) const LoadingOverlay(message: 'Applying filters...'),
      ],
    );
  }
}
