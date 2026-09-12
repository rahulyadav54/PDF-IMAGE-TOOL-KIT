import 'dart:io';

import 'package:flutter/material.dart';

import '../models/scan_page.dart';

class ScanPagesList extends StatelessWidget {
  const ScanPagesList({
    super.key,
    required this.pages,
    required this.onReorder,
    required this.onTap,
    required this.onRemove,
  });

  final List<ScanPage> pages;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(ScanPage page) onTap;
  final void Function(ScanPage page) onRemove;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pages.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final page = pages[index];
        return Card(
          key: ValueKey(page.id),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: () => onTap(page),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(page.displayImagePath),
                width: 48,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
              ),
            ),
            title: Text('Page ${index + 1}'),
            subtitle: const Text('Tap to auto-enhance like CamScanner'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onRemove(page),
                  tooltip: 'Remove page',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
