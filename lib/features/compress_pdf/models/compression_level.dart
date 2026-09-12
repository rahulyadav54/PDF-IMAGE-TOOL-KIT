/// User-selectable PDF compression presets.
enum CompressionLevel {
  low(
    label: 'Low',
    description: 'Smaller file, lower image quality',
    estimatedRatio: 0.40,
    jpegQuality: 42,
    renderScale: 1.25,
    useRasterize: true,
  ),
  medium(
    label: 'Medium',
    description: 'Balanced size and quality',
    estimatedRatio: 0.58,
    jpegQuality: 62,
    renderScale: 1.75,
    useRasterize: true,
  ),
  high(
    label: 'High',
    description: 'Better quality, larger file',
    estimatedRatio: 0.82,
    jpegQuality: 88,
    renderScale: 2.5,
    useRasterize: false,
  );

  const CompressionLevel({
    required this.label,
    required this.description,
    required this.estimatedRatio,
    required this.jpegQuality,
    required this.renderScale,
    required this.useRasterize,
  });

  final String label;
  final String description;

  /// Approximate output size as a fraction of original (for estimates only).
  final double estimatedRatio;
  final int jpegQuality;
  final double renderScale;

  /// High quality preserves vectors/text via stream compression.
  /// Low/Medium rasterize pages for stronger size reduction on image-heavy PDFs.
  final bool useRasterize;

  static int estimateCompressedSize(int originalBytes, CompressionLevel level) {
    return (originalBytes * level.estimatedRatio).round();
  }
}
