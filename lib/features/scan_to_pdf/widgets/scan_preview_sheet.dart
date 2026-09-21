import 'dart:io';

import 'package:flutter/material.dart';

import '../models/scan_page.dart';

/// Preview of a processed scan with quick actions.
class ScanPreviewSheet extends StatelessWidget {
  const ScanPreviewSheet({
    super.key,
    required this.page,
    required this.onRetake,
    required this.onCrop,
    required this.onEnhance,
    required this.onDone,
  });

  final ScanPage page;
  final VoidCallback onRetake;
  final VoidCallback onCrop;
  final VoidCallback onEnhance;
  final VoidCallback onDone;

  static Future<void> show(
    BuildContext context, {
    required ScanPage page,
    required VoidCallback onRetake,
    required VoidCallback onCrop,
    required VoidCallback onEnhance,
    required VoidCallback onDone,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ScanPreviewSheet(
        page: page,
        onRetake: () {
          Navigator.pop(context);
          onRetake();
        },
        onCrop: () {
          Navigator.pop(context);
          onCrop();
        },
        onEnhance: () {
          Navigator.pop(context);
          onEnhance();
        },
        onDone: () {
          Navigator.pop(context);
          onDone();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Scan Preview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Image.file(
                File(page.displayImagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRetake,
                  child: const Text('Retake'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onCrop,
                  child: const Text('Crop'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onEnhance,
                  child: const Text('Enhance'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onDone,
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
