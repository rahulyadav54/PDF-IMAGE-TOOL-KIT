enum WorkflowInputType {
  images,
  pdf,
  scan,
}

enum WorkflowOperationType {
  enhance,
  ocr,
  createPdf,
  compress,
  protect,
  searchablePdf,
}

class WorkflowOperationStep {
  const WorkflowOperationStep({
    required this.operation,
    required this.label,
    this.config = const {},
    this.enabled = true,
  });

  final WorkflowOperationType operation;
  final String label;
  final Map<String, dynamic> config;
  final bool enabled;
}
