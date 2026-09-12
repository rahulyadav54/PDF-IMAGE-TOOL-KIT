/// An image queued for PDF conversion.
class ImagePdfItem {
  const ImagePdfItem({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
    this.thumbnailPath,
    this.selectedForEnhancement = true,
    this.processedPath,
    this.failed = false,
    this.failureMessage,
  });

  final String id;
  final String filePath;
  final String fileName;
  final int fileSizeBytes;
  final String? thumbnailPath;
  final bool selectedForEnhancement;
  final String? processedPath;
  final bool failed;
  final String? failureMessage;

  String get displayPath => processedPath ?? filePath;

  ImagePdfItem copyWith({
    String? thumbnailPath,
    bool? selectedForEnhancement,
    String? processedPath,
    bool? failed,
    String? failureMessage,
    bool clearProcessedPath = false,
    bool clearFailure = false,
  }) {
    return ImagePdfItem(
      id: id,
      filePath: filePath,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      selectedForEnhancement:
          selectedForEnhancement ?? this.selectedForEnhancement,
      processedPath: clearProcessedPath ? null : processedPath ?? this.processedPath,
      failed: clearFailure ? false : failed ?? this.failed,
      failureMessage: clearFailure ? null : failureMessage ?? this.failureMessage,
    );
  }
}
