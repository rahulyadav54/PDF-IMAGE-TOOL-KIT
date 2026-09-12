enum PdfPageIssueKind {
  rotated,
  largeBorders,
  lowContrast,
  blurry,
  scanned,
  mixedPageSize,
  blank,
  good,
}

class PdfPageIssue {
  const PdfPageIssue({
    required this.pageIndex,
    required this.kind,
    required this.message,
    this.fixable = true,
  });

  final int pageIndex;
  final PdfPageIssueKind kind;
  final String message;
  final bool fixable;
}

class PdfHealthReport {
  const PdfHealthReport({
    required this.pageCount,
    required this.issues,
    required this.goodPageCount,
  });

  final int pageCount;
  final List<PdfPageIssue> issues;
  final int goodPageCount;

  int countFor(PdfPageIssueKind kind) =>
      issues.where((i) => i.kind == kind).length;

  bool get hasFixableIssues => issues.any((i) => i.fixable);

  List<PdfPageIssue> fixableIssues() =>
      issues.where((i) => i.fixable).toList();
}

class PdfFixPreview {
  PdfFixPreview({
    required this.pageIndex,
    required this.description,
    this.selected = true,
  });

  final int pageIndex;
  final String description;
  bool selected;
}
