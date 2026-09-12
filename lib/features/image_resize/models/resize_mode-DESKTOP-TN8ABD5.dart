enum ResizeMode {
  dimensions('Custom Size', 'Set exact width and height in pixels'),
  percentage('Percentage', 'Scale by a percentage of the original'),
  targetSize('Target File Size', 'Approximate a target output size');

  const ResizeMode(this.label, this.description);

  final String label;
  final String description;
}

enum ImageOrientation {
  portrait('Portrait', 'Taller than wide'),
  landscape('Landscape', 'Wider than tall');

  const ImageOrientation(this.label, this.description);

  final String label;
  final String description;
}
