class BatchFileItem {
  const BatchFileItem({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
    this.pageCount,
  });

  final String id;
  final String filePath;
  final String fileName;
  final int fileSizeBytes;
  final int? pageCount;
}
