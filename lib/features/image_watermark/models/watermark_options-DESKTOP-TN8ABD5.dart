enum WatermarkPosition {
  topLeft('Top Left'),
  topRight('Top Right'),
  center('Center'),
  bottomLeft('Bottom Left'),
  bottomRight('Bottom Right');

  const WatermarkPosition(this.label);
  final String label;
}

enum WatermarkMode {
  text('Text'),
  image('Logo');

  const WatermarkMode(this.label);
  final String label;
}

class WatermarkOptions {
  const WatermarkOptions({
    this.mode = WatermarkMode.text,
    this.text = 'CONFIDENTIAL',
    this.logoPath,
    this.position = WatermarkPosition.bottomRight,
    this.opacity = 0.45,
    this.scale = 1.0,
  });

  final WatermarkMode mode;
  final String text;
  final String? logoPath;
  final WatermarkPosition position;
  final double opacity;
  final double scale;

  WatermarkOptions copyWith({
    WatermarkMode? mode,
    String? text,
    String? logoPath,
    WatermarkPosition? position,
    double? opacity,
    double? scale,
  }) {
    return WatermarkOptions(
      mode: mode ?? this.mode,
      text: text ?? this.text,
      logoPath: logoPath ?? this.logoPath,
      position: position ?? this.position,
      opacity: opacity ?? this.opacity,
      scale: scale ?? this.scale,
    );
  }
}
