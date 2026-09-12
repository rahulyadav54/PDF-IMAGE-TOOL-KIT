import 'package:flutter/material.dart';

import '../models/processing_job.dart';
import 'processing_screen.dart';

/// Bridges live progress values into the standard [ProcessingScreen].
class ProcessingJobOverlay extends StatelessWidget {
  const ProcessingJobOverlay({
    super.key,
    required this.title,
    required this.completed,
    required this.total,
    this.failed = 0,
    this.currentLabel,
    this.onCancel,
  });

  final String title;
  final int completed;
  final int total;
  final int failed;
  final String? currentLabel;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final safeTotal = total > 0 ? total : 1;
    final job = ProcessingJob(
      id: 'active',
      title: title,
      type: 'bulk',
      totalItems: safeTotal,
      completedItems: completed.clamp(0, safeTotal),
      failedItems: failed,
      currentItem: completed < safeTotal ? completed + 1 : completed,
      currentLabel: currentLabel,
      status: ProcessingStatus.processing,
    );
    return ProcessingScreen(job: job, onCancel: onCancel);
  }
}
