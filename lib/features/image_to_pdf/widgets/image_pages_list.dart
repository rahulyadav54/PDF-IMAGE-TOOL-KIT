import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/utils/file_size_formatter.dart';
import '../models/image_pdf_item.dart';

class ImagePagesList extends StatelessWidget {
  const ImagePagesList({
    super.key,
    required this.images,
    required this.onReorder,
    required this.onPreview,
    required this.onRemove,
    this.onToggleEnhance,
    this.showEnhanceToggle = false,
  });

  final List<ImagePdfItem> images;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(ImagePdfItem image) onPreview;
  final void Function(ImagePdfItem image) onRemove;
  final void Function(ImagePdfItem image, bool selected)? onToggleEnhance;
  final bool showEnhanceToggle;

  @override
  Widget build(BuildContext context) {
    if (images.length > 24) {
      return _ImageGrid(
        images: images,
        onPreview: onPreview,
        onRemove: onRemove,
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      onReorder: onReorder,
      itemBuilder: (context, index) => _ImageRow(
        key: ValueKey(images[index].id),
        image: images[index],
        index: index,
        onPreview: onPreview,
        onRemove: onRemove,
        onToggleEnhance: onToggleEnhance,
        showEnhanceToggle: showEnhanceToggle,
      ),
    );
  }
}

class _ImageRow extends StatelessWidget {
  const _ImageRow({
    super.key,
    required this.image,
    required this.index,
    required this.onPreview,
    required this.onRemove,
    this.onToggleEnhance,
    this.showEnhanceToggle = false,
  });

  final ImagePdfItem image;
  final int index;
  final void Function(ImagePdfItem image) onPreview;
  final void Function(ImagePdfItem image) onRemove;
  final void Function(ImagePdfItem image, bool selected)? onToggleEnhance;
  final bool showEnhanceToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => onPreview(image),
        leading: _Thumbnail(image: image),
        title: Text(
          'Page ${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          image.failed
              ? image.failureMessage ?? 'Could not process'
              : '${image.fileName} • ${FileSizeFormatter.format(image.fileSizeBytes)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showEnhanceToggle && onToggleEnhance != null)
              Checkbox(
                value: image.selectedForEnhancement,
                onChanged: (value) =>
                    onToggleEnhance?.call(image, value ?? false),
              ),
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => onRemove(image),
              tooltip: 'Remove image',
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({
    required this.images,
    required this.onPreview,
    required this.onRemove,
  });

  final List<ImagePdfItem> images;
  final void Function(ImagePdfItem image) onPreview;
  final void Function(ImagePdfItem image) onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return InkWell(
          onTap: () => onPreview(image),
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _Thumbnail(image: image, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                left: 6,
                top: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 16, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.45),
                  ),
                  onPressed: () => onRemove(image),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.image,
    this.fit = BoxFit.cover,
  });

  final ImagePdfItem image;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final path = image.thumbnailPath ?? image.filePath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(path),
        width: fit == BoxFit.cover ? null : 48,
        height: fit == BoxFit.cover ? null : 64,
        fit: fit,
        cacheWidth: 160,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}
