import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/services/temp_file_service.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../models/scan_enhance_kind.dart';
import '../models/scan_page.dart';
import '../providers/scan_session_provider.dart';
import '../services/image_enhancement_service.dart';
import 'document_corner_editor_sheet.dart';

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
  String? _previewPath;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _enhanceKind = widget.page.enhanceKind;
    _previewPath = widget.page.displayImagePath;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_enhanceKind == ScanEnhanceKind.original) {
        setState(() => _previewPath = widget.page.originalImagePath);
      } else {
        _applyPreview();
      }
    });
  }

  Future<void> _applyPreview() async {
    setState(() => _isProcessing = true);
    try {
      final service = ref.read(imageEnhancementServiceProvider);
      final result = await service.applyEnhancements(
        sourcePath: widget.page.originalImagePath,
        kind: _enhanceKind,
        maxDimension: AppConstants.enhancementPreviewMaxDimension,
        jpegQuality: 78,
        preview: true,
        useCache: false,
      );
      if (mounted) {
        await _deleteSupersededPreview(result.path);
        setState(() => _previewPath = result.path);
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
    setState(() => _enhanceKind = preset.kind);
    if (preset.kind == ScanEnhanceKind.original) {
      setState(() => _previewPath = widget.page.originalImagePath);
      return;
    }
    await _applyPreview();
  }

  Future<void> _openCrop() async {
    final updated = await DocumentCornerEditorSheet.show(context, page: widget.page);
    if (updated == null || !mounted) return;

    await ref.read(scanSessionProvider.notifier).enhanceAllPages(
      pageIds: [updated.id],
    );

    final refreshed = ref.read(scanSessionProvider).firstWhere(
          (p) => p.id == updated.id,
          orElse: () => updated,
        );

    setState(() {
      _previewPath = refreshed.displayImagePath;
      _enhanceKind = ScanEnhanceKind.auto;
    });
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
      final result = await service.applyEnhancements(
        sourcePath: widget.page.originalImagePath,
        kind: _enhanceKind,
        preview: false,
      );
      await _deleteSupersededPreview(result.path);
      widget.onSave(
        widget.page.copyWith(
          displayImagePath: result.path,
          enhanceKind: result.applied ? _enhanceKind : widget.page.enhanceKind,
          brightness: 0,
          contrast: 0,
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
                'Enhance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap a mode to update the preview instantly.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ScanEnhancementPreset.scanModes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final preset = ScanEnhancementPreset.scanModes[index];
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: Image.file(
                      File(_previewPath ?? widget.page.displayImagePath),
                      key: ValueKey(_previewPath ?? widget.page.displayImagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isProcessing ? null : _openCrop,
                icon: const Icon(Icons.crop_free_outlined, size: 18),
                label: const Text('Adjust Corners'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _isProcessing ? null : _save,
                child: const Text('Done'),
              ),
            ],
          ),
        ),
        if (_isProcessing)
          const LoadingOverlay(message: 'Processing...'),
      ],
    );
  }
}
