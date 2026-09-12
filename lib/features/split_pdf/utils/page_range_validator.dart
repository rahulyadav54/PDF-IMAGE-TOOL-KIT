/// Validates and converts 1-based page ranges for PDF splitting.
class PageRangeValidator {
  PageRangeValidator._();

  static String? validate(int start, int end, int totalPages) {
    if (totalPages <= 0) return 'This PDF has no pages.';
    if (start < 1 || end < 1) return 'Page numbers must be at least 1.';
    if (start > totalPages || end > totalPages) {
      return 'Page numbers cannot exceed $totalPages.';
    }
    if (start > end) {
      return 'Start page must be less than or equal to end page.';
    }
    return null;
  }

  static List<int> toPageIndices(int start, int end) {
    return List.generate(end - start + 1, (index) => start - 1 + index);
  }
}
