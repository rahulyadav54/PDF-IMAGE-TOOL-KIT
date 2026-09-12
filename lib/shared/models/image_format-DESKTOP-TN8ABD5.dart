/// Supported image formats for convert, compress, and resize tools.
enum ImageFormat {
  jpg('JPG', 'jpg', ['jpg', 'jpeg']),
  png('PNG', 'png', ['png']),
  webp('WEBP', 'webp', ['webp']),
  bmp('BMP', 'bmp', ['bmp']),
  gif('GIF', 'gif', ['gif']);

  const ImageFormat(this.label, this.extension, this.aliases);

  final String label;
  final String extension;
  final List<String> aliases;

  String get dottedExtension => '.$extension';

  bool get supportsQuality => this == jpg || this == webp;

  /// WEBP can be decoded but not encoded with the current on-device library.
  bool get supportsEncoding => this != webp;

  static ImageFormat? fromExtension(String extension) {
    final normalized = extension.toLowerCase().replaceAll('.', '');
    for (final format in values) {
      if (format.aliases.contains(normalized)) {
        return format;
      }
    }
    return null;
  }

  static ImageFormat? fromPath(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return null;
    return fromExtension(path.substring(dot + 1));
  }
}
