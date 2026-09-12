/// A PDF file queued for merging.
class MergePdfItem {
  const MergePdfItem({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.pageCount,
    required this.fileSizeBytes,
  });

  final String id;
  final String filePath;
  final String fileName;
  final int pageCount;
  final int fileSizeBytes;
}
