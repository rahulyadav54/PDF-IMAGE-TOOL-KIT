import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../scan_to_pdf/models/scan_enhance_kind.dart';
import '../../scan_to_pdf/services/image_enhancement_service.dart';
import '../models/image_pdf_item.dart';

/// Fast low-resolution enhancement preview before full-res PDF export.
class ImageEnhancementPreviewDialog extends ConsumerStatefulWidget {
  const ImageEnhancementPreviewDialog({super.key, required this.image});

  final ImagePdfItem image;

  static Future<void> show(BuildContext context, ImagePdfItem image) {
    return showDialog<void>(
      context: context,
      builder: (context) => ImageEnhancementPreviewDialog(image: image),
    );
  }

  @override
  ConsumerState<ImageEnhancementPreviewDialog> createState() =>
      _ImageEnhancementPreviewDialogState();
}

class _ImageEnhancementPreviewDialogState
    extends ConsumerState<ImageEnhancementPreviewDialog> {
  ScanEnhanceKind _mode = ScanEnhanceKind.auto;
  String? _previewPath;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreview(_mode));
  }

  Future<void> _loadPreview(ScanEnhanceKind kind) async {
    setState(() {
      _mode = kind;
      _loading = true;
    });
    try {
      final path = await ref.read(imageEnhancementServiceProvider).applyEnhancements(
            sourcePath: widget.image.filePath,
            kind: kind,
            maxDimension: AppConstants.enhancementPreviewMaxDimension,
            jpegQuality: 75,
            preview: true,
            useCache: true,
          );
      if (mounted) setState(() => _previewPath = path);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final displayPath = _previewPath ?? widget.image.filePath;

    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.image.fileName,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip('Original', ScanEnhanceKind.original),
                _chip('Auto', ScanEnhanceKind.auto),
                _chip('Document', ScanEnhanceKind.document),
                _chip('B&W', ScanEnhanceKind.blackWhite),
                _chip('Magic', ScanEnhanceKind.magicColor),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: size.height * 0.5,
            width: size.width * 0.85,
            child: Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  child: Image.file(
                    File(displayPath),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined, size: 64),
                  ),
                ),
                if (_loading)
                  const CircularProgressIndicator(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Fast preview • full quality applied when creating PDF',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, ScanEnhanceKind kind) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _mode == kind,
        onSelected: _loading ? null : (_) => _loadPreview(kind),
      ),
    );
  }
}
