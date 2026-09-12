import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/services/temp_file_service.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../models/scan_enhance_kind.dart';
import '../models/scan_page.dart';
import '../services/image_enhancement_service.dart';

class PageEditorSheet extends ConsumerStatefulWidget {
  const PageEditorSheet({
    super.key,
    required this.page,
    required this.onSave,
  });

  final ScanPage page;
  final ValueChanged<ScanPage> onSave;

  @override
  ConsumerState<PageEditorSheet> createState() => _PageEditorSheetState();
}

class _PageEditorSheetState extends ConsumerState<PageEditorSheet> {
  late ScanEnhanceKind _enhanceKind;
  late double _brightness;
  late double _contrast;
  String? _previewPath;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _enhanceKind = widget.page.enhanceKind;
    _brightness = widget.page.brightness;
    _contrast = widget.page.contrast;
    _previewPath = widget.page.displayImagePath;

    if (_enhanceKind == ScanEnhanceKind.original) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyPreset(ScanEnhancementPreset.magicColor);
      });
    }
  }

  Future<void> _applyPreview() async {
    setState(() => _isProcessing = true);
    try {
      final service = ref.read(imageEnhancementServiceProvider);
      final path = await service.applyEnhancements(
        sourcePath: widget.page.originalImagePath,
        kind: _enhanceKind,
        brightness: _brightness,
        contrast: _contrast,
        maxDimension: 640,
        jpegQuality: 78,
        preview: true,
        useCache: false,
      );
      if (mounted) {
        await _deleteSupersededPreview(path);
        setState(() => _previewPath = path);
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _applyPreset(ScanEnhancementPreset preset) async {
    setState(() {
      _enhanceKind = preset.kind;
      _brightness = preset.brightness;
      _contrast = preset.contrast;
    });
    await _applyPreview();
  }

  Future<void> _deleteSupersededPreview(String nextPath) async {
    final previous = _previewPath;
    if (previous == null || previous == nextPath) return;
    if (previous == widget.page.originalImagePath) return;

    final tempService = ref.read(tempFileServiceProvider);
    if (tempService.isManagedTempPath(previous)) {
      await tempService.delete(previous);
    }
  }

  @override
  void dispose() {
    final preview = _previewPath;
    if (preview != null &&
        preview != widget.page.displayImagePath &&
        preview != widget.page.originalImagePath) {
      final tempService = ref.read(tempFileServiceProvider);
      if (tempService.isManagedTempPath(preview)) {
        tempService.delete(preview);
      }
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isProcessing = true);
    try {
      final service = ref.read(imageEnhancementServiceProvider);
      final path = await service.applyEnhancements(
        sourcePath: widget.page.originalImagePath,
        kind: _enhanceKind,
        brightness: _brightness,
        contrast: _contrast,
        preview: false,
      );
      await _deleteSupersededPreview(path);
      widget.onSave(
        widget.page.copyWith(
          displayImagePath: path,
          enhanceKind: _enhanceKind,
          brightness: _brightness,
          contrast: _contrast,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enhance Page',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Magic Color lifts dim text like CamScanner. B&W is best for printed documents.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ScanEnhancementPreset.all.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final preset = ScanEnhancementPreset.all[index];
                    final selected = _enhanceKind == preset.kind;
                    return ChoiceChip(
                      label: Text(preset.label),
                      selected: selected,
                      onSelected: _isProcessing
                          ? null
                          : (_) => _applyPreset(preset),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Image.file(
                    File(_previewPath ?? widget.page.originalImagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Brightness: ${_brightness.round()}'),
              Slider(
                value: _brightness,
                min: -40,
                max: 40,
                divisions: 32,
                onChanged: (v) => setState(() => _brightness = v),
                onChangeEnd: (_) => _applyPreview(),
              ),
              Text('Contrast: ${_contrast.round()}'),
              Slider(
                value: _contrast,
                min: -40,
                max: 40,
                divisions: 32,
                onChanged: (v) => setState(() => _contrast = v),
                onChangeEnd: (_) => _applyPreview(),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _isProcessing ? null : _save,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
        if (_isProcessing)
          const LoadingOverlay(message: 'Enhancing document...'),
      ],
    );
  }
}
