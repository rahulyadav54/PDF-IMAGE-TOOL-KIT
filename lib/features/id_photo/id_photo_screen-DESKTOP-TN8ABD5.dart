import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../shared/providers/recent_files_provider.dart';
import '../../shared/services/file_actions_service.dart';
import '../../shared/services/file_service.dart';
import '../../shared/services/recent_files_service.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/result_screen.dart';
import '../image_to_pdf/services/image_validation_service.dart';
import '../scan_to_pdf/services/document_scanner_service.dart';
import 'models/id_photo_options.dart';
import 'models/id_photo_preset.dart';
import 'services/id_photo_service.dart';

class IdPhotoScreen extends ConsumerStatefulWidget {
  const IdPhotoScreen({super.key});

  @override
  ConsumerState<IdPhotoScreen> createState() => _IdPhotoScreenState();
}

class _IdPhotoScreenState extends ConsumerState<IdPhotoScreen> {
  String? _selectedPath;
  ImageValidationResult? _validation;
  IdPhotoPreset _preset = IdPhotoPreset.presets.first;
  IdPhotoOptions _options = const IdPhotoOptions();
  Uint8List? _previewBytes;
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isPreviewLoading = false;
  String? _error;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    await _loadImage(() => ref.read(fileServiceProvider).pickFile(
          allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'heic', 'heif'],
        ));
  }

  Future<void> _takePhoto() async {
    await _loadImage(() async {
      final path = await ref.read(documentScannerServiceProvider).scanSinglePage();
      return path;
    });
  }

  Future<void> _loadImage(Future<String?> Function() pick) async {
    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      final path = await pick();
      if (path == null || path.isEmpty) return;

      final validation = await ref.read(imageValidationServiceProvider).validate(path);
      setState(() {
        _selectedPath = path;
        _validation = validation;
        _previewBytes = null;
      });
      await _refreshPreview();
    } on AppException catch (e) {
      if (e is FilePickerCancelledException) return;
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Unable to load photo. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshPreview() async {
    if (_selectedPath == null) return;

    setState(() => _isPreviewLoading = true);
    try {
      final bytes = await ref.read(idPhotoServiceProvider).previewJpeg(
            inputPath: _selectedPath!,
            preset: _preset,
            options: _options,
          );
      if (mounted) setState(() => _previewBytes = bytes);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not generate preview.');
    } finally {
      if (mounted) setState(() => _isPreviewLoading = false);
    }
  }

  Future<void> _create() async {
    if (_selectedPath == null) return;

    setState(() {
      _error = null;
      _isProcessing = true;
    });

    try {
      final result = await ref.read(idPhotoServiceProvider).create(
            inputPath: _selectedPath!,
            preset: _preset,
            options: _options,
          );

      final entry = await ref.read(recentFilesServiceProvider).createEntry(
            filePath: result.outputPath,
            operation: 'ID Photo',
            fileSizeBytes: result.outputSizeBytes,
          );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: 'ID Photo Ready',
            outputPath: result.outputPath,
            fileActions: ref.read(fileActionsServiceProvider),
            subtitle: result.fileName,
            newSizeBytes: result.outputSizeBytes,
            conversionLabel: '${result.preset.name} • ${result.width}×${result.height} px',
            onProcessAnother: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedPath = null;
                _validation = null;
                _previewBytes = null;
              });
            },
          ),
        ),
      );
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to create ID photo. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _updatePreset(IdPhotoPreset preset) {
    setState(() => _preset = preset);
    _refreshPreview();
  }

  void _updateOptions(IdPhotoOptions options) {
    setState(() => _options = options);
    _refreshPreview();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('ID Photo Maker')),
          body: SafeArea(
            child: _selectedPath == null ? _buildPickStep(context) : _buildEditStep(context, scheme),
          ),
        ),
        if (_isLoading) const LoadingOverlay(message: 'Loading photo...'),
        if (_isProcessing) const LoadingOverlay(message: 'Creating ID photo...'),
      ],
    );
  }

  Widget _buildPickStep(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create ID Photo', style: AppTypography.screenTitle(context)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Take or choose a portrait photo. Crop, background, and size will be applied automatically.',
            style: AppTypography.cardSubtitle(context),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: TextStyle(color: AppColors.red, fontSize: 13)),
          ],
          const Spacer(),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: const Center(
              child: Icon(Icons.badge_outlined, size: 56, color: AppColors.electricBlue),
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _isLoading ? null : _takePhoto,
            icon: const Icon(Icons.camera_alt_outlined, size: 20),
            label: const Text('Take Photo'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _pickFromGallery,
            icon: const Icon(Icons.photo_library_outlined, size: 20),
            label: const Text('Choose from Gallery'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditStep(BuildContext context, ColorScheme scheme) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      children: [
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.red.withValues(alpha: 0.2)),
            ),
            child: Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
          ),
        ],
        Text('Preview', style: AppTypography.sectionTitle(context)),
        const SizedBox(height: AppSpacing.sm),
        AspectRatio(
          aspectRatio: _preset.widthMm / _preset.heightMm,
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: _isPreviewLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _previewBytes != null
                    ? Image.memory(_previewBytes!, fit: BoxFit.cover)
                    : Image.file(File(_selectedPath!), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                _validation!.fileName,
                style: AppTypography.caption(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: _isProcessing ? null : _pickFromGallery,
              child: const Text('Change'),
            ),
          ],
        ),
        Text(
          '${_validation!.width}×${_validation!.height} • ${FileSizeFormatter.format(_validation!.fileSizeBytes)}',
          style: AppTypography.caption(context),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Photo size', style: AppTypography.sectionTitle(context)),
        const SizedBox(height: AppSpacing.sm),
        ...IdPhotoPreset.presets.map((preset) {
          final selected = preset.id == _preset.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Material(
              color: selected
                  ? AppColors.electricBlue.withValues(alpha: 0.08)
                  : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _isProcessing ? null : () => _updatePreset(preset),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected ? AppColors.electricBlue : scheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        selected ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 20,
                        color: selected ? AppColors.electricBlue : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(preset.name, style: AppTypography.cardTitle(context)),
                            Text(
                              '${preset.sizeLabel} • ${preset.widthPx()}×${preset.heightPx()} px',
                              style: AppTypography.caption(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: AppSpacing.lg),
        Text('Background', style: AppTypography.sectionTitle(context)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: IdPhotoBackground.values.map((bg) {
            final selected = _options.background.id == bg.id;
            return ChoiceChip(
              label: Text(bg.label),
              selected: selected,
              onSelected: _isProcessing
                  ? null
                  : (_) => _updateOptions(_options.copyWith(background: bg)),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Adjust face position', style: AppTypography.sectionTitle(context)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Move up if the head is cut off, or down to include more shoulders.',
          style: AppTypography.caption(context),
        ),
        Slider(
          value: _options.verticalFocus,
          min: 0.15,
          max: 0.65,
          divisions: 10,
          label: '${(_options.verticalFocus * 100).round()}%',
          onChanged: _isProcessing
              ? null
              : (value) => _updateOptions(_options.copyWith(verticalFocus: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: _isProcessing || _isPreviewLoading ? null : _create,
          icon: const Icon(Icons.download_outlined, size: 20),
          label: Text('Save ${_preset.name} Photo'),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
