import 'package:flutter/material.dart';

import '../../../shared/models/tool_type.dart';
import 'workflow_operation.dart';

class WorkflowStep {
  const WorkflowStep({
    required this.label,
    required this.route,
    required this.icon,
  });

  final String label;
  final String route;
  final IconData icon;
}

class WorkflowDefinition {
  const WorkflowDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.steps,
    this.isPro = false,
    this.inputType = WorkflowInputType.images,
    this.operations = const [],
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<WorkflowStep> steps;
  final bool isPro;
  final WorkflowInputType inputType;
  final List<WorkflowOperationStep> operations;
}

typedef ExecutableWorkflow = WorkflowDefinition;
abstract final class WorkflowCatalog {
  static final scanCompressLock = WorkflowDefinition(
    id: 'scan_compress_lock',
    title: 'Scan → Compress → Lock',
    description: 'Scan a document, reduce size, then password-protect it.',
    icon: Icons.document_scanner_outlined,
    steps: [
      WorkflowStep(
        label: 'Scan to PDF',
        route: ToolType.scanToPdf.route,
        icon: Icons.document_scanner_outlined,
      ),
      WorkflowStep(
        label: 'Compress PDF',
        route: ToolType.compressPdf.route,
        icon: Icons.compress_rounded,
      ),
      WorkflowStep(
        label: 'Lock PDF',
        route: ToolType.protectPdf.route,
        icon: Icons.lock_rounded,
      ),
    ],
  );

  static final imagesToPdfCompress = WorkflowDefinition(
    id: 'images_pdf_compress',
    title: 'Images → PDF → Compress',
    description: 'Convert photos to PDF and shrink the file size.',
    icon: Icons.picture_as_pdf_rounded,
    inputType: WorkflowInputType.images,
    operations: const [
      WorkflowOperationStep(
        operation: WorkflowOperationType.createPdf,
        label: 'Create PDF',
      ),
      WorkflowOperationStep(
        operation: WorkflowOperationType.compress,
        label: 'Compress PDF',
      ),
    ],
    steps: [
      WorkflowStep(
        label: 'Image to PDF',
        route: ToolType.imageToPdf.route,
        icon: Icons.picture_as_pdf_rounded,
      ),
      WorkflowStep(
        label: 'Compress PDF',
        route: ToolType.compressPdf.route,
        icon: Icons.compress_rounded,
      ),
    ],
  );

  static final collegeAssignment = WorkflowDefinition(
    id: 'college_assignment',
    title: 'College Assignment',
    description: 'Enhance scans, create A4 PDF, and compress.',
    icon: Icons.school_outlined,
    inputType: WorkflowInputType.images,
    operations: const [
      WorkflowOperationStep(
        operation: WorkflowOperationType.enhance,
        label: 'Enhance',
        config: {'mode': 'document'},
      ),
      WorkflowOperationStep(
        operation: WorkflowOperationType.createPdf,
        label: 'Create PDF',
      ),
      WorkflowOperationStep(
        operation: WorkflowOperationType.compress,
        label: 'Compress PDF',
      ),
    ],
    steps: const [],
  );

  static final scanSearchable = WorkflowDefinition(
    id: 'scan_searchable',
    title: 'Scan → Searchable PDF',
    description: 'Scan documents and make them searchable with OCR.',
    icon: Icons.manage_search_rounded,
    steps: [
      WorkflowStep(
        label: 'Scan to PDF',
        route: ToolType.scanToPdf.route,
        icon: Icons.document_scanner_outlined,
      ),
      WorkflowStep(
        label: 'Searchable PDF',
        route: ToolType.searchablePdf.route,
        icon: Icons.manage_search_rounded,
      ),
    ],
    isPro: true,
  );

  static final signAndLock = WorkflowDefinition(
    id: 'sign_lock',
    title: 'Sign → Lock',
    description: 'Add your signature then protect the document.',
    icon: Icons.draw_outlined,
    steps: [
      WorkflowStep(
        label: 'Sign PDF',
        route: ToolType.signPdf.route,
        icon: Icons.draw_outlined,
      ),
      WorkflowStep(
        label: 'Lock PDF',
        route: ToolType.protectPdf.route,
        icon: Icons.lock_rounded,
      ),
    ],
  );

  static List<WorkflowDefinition> get all => [
        collegeAssignment,
        imagesToPdfCompress,
        scanCompressLock,
        scanSearchable,
        signAndLock,
      ];

  static List<WorkflowDefinition> get executable =>
      all.where((w) => w.operations.isNotEmpty).toList();
}
