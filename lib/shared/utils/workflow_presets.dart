import 'package:flutter/material.dart';

import '../models/tool_type.dart';
import '../models/workflow_action.dart';

/// Suggested next-step workflows shown on result screens.
abstract final class WorkflowPresets {
  static List<WorkflowAction> forPdfOutput() => [
        WorkflowAction(
          label: 'Compress',
          icon: Icons.compress_rounded,
          route: ToolType.compressPdf.route,
        ),
        WorkflowAction(
          label: 'Lock PDF',
          icon: Icons.lock_rounded,
          route: ToolType.protectPdf.route,
        ),
        WorkflowAction(
          label: 'Edit PDF',
          icon: Icons.edit_note_rounded,
          route: ToolType.editPdf.route,
        ),
      ];

  static List<WorkflowAction> forScanResult() => [
        WorkflowAction(
          label: 'Compress',
          icon: Icons.compress_rounded,
          route: ToolType.compressPdf.route,
        ),
        WorkflowAction(
          label: 'Share',
          icon: Icons.share_outlined,
          route: '__share__',
          passOutputPath: false,
        ),
      ];

  static List<WorkflowAction> forImageOutput() => [
        WorkflowAction(
          label: 'Image to PDF',
          icon: Icons.picture_as_pdf_rounded,
          route: ToolType.imageToPdf.route,
        ),
        WorkflowAction(
          label: 'Compress',
          icon: Icons.photo_size_select_small_rounded,
          route: ToolType.imageCompress.route,
        ),
        WorkflowAction(
          label: 'Add Watermark',
          icon: Icons.water_drop_outlined,
          route: ToolType.imageWatermark.route,
        ),
      ];
}
