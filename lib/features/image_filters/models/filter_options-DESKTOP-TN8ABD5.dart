enum FilterPreset {
  none('Original'),
  blackWhite('Black & White'),
  vintage('Vintage'),
  vivid('Vivid'),
  sharpen('Sharpen');

  const FilterPreset(this.label);
  final String label;
}

class FilterOptions {
  const FilterOptions({
    this.preset = FilterPreset.none,
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
  });

  final FilterPreset preset;
  final int brightness;
  final int contrast;
  final int saturation;

  FilterOptions copyWith({
    FilterPreset? preset,
    int? brightness,
    int? contrast,
    int? saturation,
  }) {
    return FilterOptions(
      preset: preset ?? this.preset,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
    );
  }
}
