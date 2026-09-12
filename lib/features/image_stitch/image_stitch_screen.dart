import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../shared/providers/recent_files_provider.dart';
import '../../shared/services/entitlement_service.dart';
import '../../shared/services/file_actions_service.dart';
import '../../shared/services/file_service.dart';
import '../../shared/services/recent_files_service.dart';
import '../../shared/models/tool_type.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/tool_app_bar_title.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/result_screen.dart';
import '../../shared/widgets/step_bar.dart';
import 'models/stitch_direction.dart';
import 'services/image_stitch_service.dart';

class ImageStitchScreen extends ConsumerStatefulWidget {
  const ImageStitchScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<ImageStitchScreen> createState() => _ImageStitchScreenState();
}

class _ImageStitchScreenState extends ConsumerState<ImageStitchScreen> {
  @override
  void initState() {
    super.initState();
    final initialPath = widget.initialPath;
    if (initialPath != null && initialPath.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadImages(() async => [initialPath]);
      });
    }
  }

  List<String> _selectedPaths = [];
  StitchDirection _direction = StitchDirection.vertical;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _fatalError;

  Future<void> _pickImages() => _loadImages(
        () => ref.read(fileServiceProvider).pickMultipleFiles(
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
        ),
      );

  Future<void> _loadImages(Future<List<String>> Function() load) async {
    setState(() {
      _fatalError = null;
      _isLoading = true;
    });

    try {
      final paths = await load();
      setState(() => _selectedPaths = paths);
    } on AppException catch (e) {
      if (e is FilePickerCancelledException) return;
      setState(() => _fatalError = e.message);
    } catch (_) {
      setState(
          () => _fatalError = 'Unable to select images. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _removeAt(int index) {
    setState(() => _selectedPaths.removeAt(index));
  }

  Future<void> _stitch() async {
    if (_selectedPaths.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least 2 images to stitch.')),
      );
      return;
    }

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

      final result = await ref.read(imageStitchServiceProvider).stitch(
            inputPaths: _selectedPaths,
            direction: _direction,
          );

      await ref.read(entitlementServiceProvider).recordOperation();

      final entry = await ref.read(recentFilesServiceProvider).createEntry(
            filePath: result.outputPath,
            operation: 'Stitch Images',
            fileSizeBytes: result.outputSizeBytes,
          );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: 'Images Stitched',
            outputPath: result.outputPath,
            fileActions: ref.read(fileActionsServiceProvider),
            subtitle: result.fileName,
            newSizeBytes: result.outputSizeBytes,
            conversionLabel:
                '${result.imageCount} images • ${result.width}×${result.height} px • ${result.direction.label}',
            onProcessAnother: () {
              Navigator.of(context).pop();
              setState(() => _selectedPaths = []);
            },
          ),
        ),
      );
    } on AppException catch (e) {
      if (mounted) setState(() => _fatalError = e.message);
    } catch (_) {
      if (mounted) {
        setState(
            () => _fatalError = 'Unable to stitch images. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return Scaffold(
        appBar:
            AppBar(title: const ToolAppBarTitle(tool: ToolType.imageStitch)),
        body: ErrorView(
          message: _fatalError!,
          onRetry: () => setState(() => _fatalError = null),
          onChooseAnother: _pickImages,
          onGoBack: () => Navigator.of(context).pop(),
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;
    final step = _selectedPaths.isEmpty ? 1 : 2;

    return Stack(
      children: [
        Scaffold(
          appBar:
              AppBar(title: const ToolAppBarTitle(tool: ToolType.imageStitch)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                StepBar(currentStep: step),
                const SizedBox(height: 20),
                if (_selectedPaths.isEmpty) ...[
                  Text(
                    'Select Images',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Combine screenshots, WhatsApp photos, or scans into one long image — great for sharing or printing.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _pickImages,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose Images'),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_selectedPaths.length} images selected',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _isProcessing ? null : _pickImages,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Change'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_selectedPaths.length, (index) {
                    final path = _selectedPaths[index];
                    final name = path.split(RegExp(r'[\\/]')).last;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(name,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed:
                              _isProcessing ? null : () => _removeAt(index),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Text(
                    'Layout',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<StitchDirection>(
                    segments: StitchDirection.values
                        .map(
                          (direction) => ButtonSegment(
                            value: direction,
                            label: Text(direction.label),
                            icon: Icon(
                              direction == StitchDirection.vertical
                                  ? Icons.view_agenda_outlined
                                  : Icons.view_week_outlined,
                            ),
                          ),
                        )
                        .toList(),
                    selected: {_direction},
                    onSelectionChanged: _isProcessing
                        ? null
                        : (selection) =>
                            setState(() => _direction = selection.first),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _direction.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : _stitch,
                    icon: const Icon(Icons.view_agenda_outlined),
                    label: const Text('Stitch Images'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(message: 'Loading images...'),
        if (_isProcessing) const LoadingOverlay(message: 'Stitching images...'),
      ],
    );
  }
}
