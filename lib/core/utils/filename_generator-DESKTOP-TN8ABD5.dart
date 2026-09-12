import 'dart:io';

/// Generates safe, descriptive output filenames without overwriting originals.
class FilenameGenerator {
  FilenameGenerator._();

  static String withSuffix(String originalPath, String suffix, {String? newExtension}) {
    final file = File(originalPath);
    final baseName = _stripExtension(file.uri.pathSegments.last);
    final ext = newExtension ?? _extension(file.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${baseName}_$suffix$timestamp$ext';
  }

  static String compressed(String originalPath) =>
      withSuffix(originalPath, 'compressed', newExtension: '.pdf');

  static String merged(String baseName) {
    final stripped = _stripExtension(baseName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${stripped}_merged_$timestamp.pdf';
  }

  static String splitPage(String originalPath, int pageNumber) {
    final baseName = _stripExtension(File(originalPath).uri.pathSegments.last);
    final padded = pageNumber.toString().padLeft(3, '0');
    return '${baseName}_split_$padded.pdf';
  }

  static String extractedRange(String originalPath, int start, int end) {
    final baseName = _stripExtension(File(originalPath).uri.pathSegments.last);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${baseName}_pages_$start-${end}_$timestamp.pdf';
  }

  static String splitZip(String originalPath) {
    final baseName = _stripExtension(File(originalPath).uri.pathSegments.last);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${baseName}_split_pages_$timestamp.zip';
  }

  static String converted(String originalPath, String newExtension) {
    final baseName = _stripExtension(File(originalPath).uri.pathSegments.last);
    final ext = newExtension.startsWith('.') ? newExtension : '.$newExtension';
    return '${baseName}_converted$ext';
  }

  static String imageCompressed(String originalPath) =>
      withSuffix(originalPath, 'compressed', newExtension: _extension(originalPath));

  static String imageResized(String originalPath, {String? newExtension}) {
    final ext = newExtension ?? _extension(originalPath);
    return withSuffix(originalPath, 'resized', newExtension: ext);
  }

  static String scanned() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'scanned_document_$timestamp.pdf';
  }

  static String imageToPdf() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'images_document_$timestamp.pdf';
  }

  static String pdfPageImage(String originalPath, int pageNumber, String extension) {
    final baseName = _stripExtension(File(originalPath).uri.pathSegments.last);
    final padded = pageNumber.toString().padLeft(3, '0');
    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    return '${baseName}_page_$padded.$ext';
  }

  static String pdfToImageZip(String originalPath) {
    final baseName = _stripExtension(File(originalPath).uri.pathSegments.last);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${baseName}_pages_$timestamp.zip';
  }

  static String protectedPdf(String originalPath) =>
      withSuffix(originalPath, 'protected', newExtension: '.pdf');

  static String editedPdf(String originalPath) =>
      withSuffix(originalPath, 'edited', newExtension: '.pdf');

  static String idPhoto(String presetSlug) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'id_photo_${presetSlug}_$timestamp.jpg';
  }

  static String stitchedImage({bool vertical = true}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final direction = vertical ? 'vertical' : 'horizontal';
    return 'stitched_${direction}_$timestamp.jpg';
  }

  static String batchZip(String operationSlug) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final slug = operationSlug.replaceAll(RegExp(r'[^a-z0-9]+'), '_').toLowerCase();
    return 'batch_${slug}_$timestamp.zip';
  }

  static String _stripExtension(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  static String _extension(String path) {
    final dot = path.lastIndexOf('.');
    return dot >= 0 ? path.substring(dot) : '';
  }
}
