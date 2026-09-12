enum ImageExportFormat {
  jpg('JPG', 'jpeg', 90),
  png('PNG', 'png', 100);

  const ImageExportFormat(this.label, this.extension, this.jpegQuality);

  final String label;
  final String extension;

  /// Used when converting raster PNG to JPEG.
  final int jpegQuality;
}

enum PageSelectionMode {
  allPages('All Pages', 'Export every page in the PDF'),
  pageRange('Selected Pages', 'Choose a specific page range');

  const PageSelectionMode(this.label, this.description);

  final String label;
  final String description;
}
