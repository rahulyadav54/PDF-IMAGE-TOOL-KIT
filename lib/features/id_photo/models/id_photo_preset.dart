class IdPhotoPreset {
  const IdPhotoPreset({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.widthMm,
    required this.heightMm,
  });

  final String id;
  final String name;
  final String subtitle;
  final double widthMm;
  final double heightMm;

  static const int defaultDpi = 300;

  int widthPx([int dpi = defaultDpi]) => _mmToPx(widthMm, dpi);

  int heightPx([int dpi = defaultDpi]) => _mmToPx(heightMm, dpi);

  String get sizeLabel => '${widthMm.toStringAsFixed(0)} × ${heightMm.toStringAsFixed(0)} mm';

  static int _mmToPx(double mm, int dpi) => (mm / 25.4 * dpi).round();

  static const List<IdPhotoPreset> presets = [
    IdPhotoPreset(
      id: 'india_passport',
      name: 'India Passport',
      subtitle: '35 × 45 mm — standard passport photo',
      widthMm: 35,
      heightMm: 45,
    ),
    IdPhotoPreset(
      id: 'india_pan',
      name: 'PAN Card',
      subtitle: '25 × 35 mm — income tax ID photo',
      widthMm: 25,
      heightMm: 35,
    ),
    IdPhotoPreset(
      id: 'india_aadhaar',
      name: 'Aadhaar',
      subtitle: '35 × 45 mm — Aadhaar enrollment photo',
      widthMm: 35,
      heightMm: 45,
    ),
    IdPhotoPreset(
      id: 'us_visa',
      name: 'US Visa',
      subtitle: '2 × 2 inch — DS-160 photo',
      widthMm: 50.8,
      heightMm: 50.8,
    ),
    IdPhotoPreset(
      id: 'schengen',
      name: 'Schengen Visa',
      subtitle: '35 × 45 mm — EU visa standard',
      widthMm: 35,
      heightMm: 45,
    ),
    IdPhotoPreset(
      id: 'resume',
      name: 'Resume / CV',
      subtitle: '400 × 400 px at 300 DPI',
      widthMm: 33.9,
      heightMm: 33.9,
    ),
  ];

  static IdPhotoPreset? byId(String id) {
    for (final preset in presets) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}
