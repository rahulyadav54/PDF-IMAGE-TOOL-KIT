import 'package:flutter/material.dart';

import 'processing_overlay.dart';

/// Processing overlay with scan animation (used across all tools).
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    this.message = 'Processing...',
    this.progress,
    this.progressLabel,
    this.showScanAnimation = true,
  });

  final String message;
  final double? progress;
  final String? progressLabel;
  final bool showScanAnimation;

  @override
  Widget build(BuildContext context) {
    return ProcessingOverlay(
      message: message,
      progress: progress,
      progressLabel: progressLabel,
      showScanAnimation: showScanAnimation && progress == null,
    );
  }
}
