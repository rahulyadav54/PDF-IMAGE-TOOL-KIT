class IdPhotoBackground {
  const IdPhotoBackground._(this.id, this.label, this.red, this.green, this.blue);

  final String id;
  final String label;
  final int? red;
  final int? green;
  final int? blue;

  bool get isOriginal => red == null;

  static const white = IdPhotoBackground._('white', 'White', 255, 255, 255);
  static const lightBlue = IdPhotoBackground._('light_blue', 'Light blue', 232, 244, 252);
  static const original = IdPhotoBackground._('original', 'Keep original', null, null, null);

  static const List<IdPhotoBackground> values = [white, lightBlue, original];

  static IdPhotoBackground byId(String id) {
    return values.firstWhere((b) => b.id == id, orElse: () => white);
  }
}

class IdPhotoOptions {
  const IdPhotoOptions({
    this.background = IdPhotoBackground.white,
    this.verticalFocus = 0.35,
    this.dpi = 300,
  });

  final IdPhotoBackground background;

  /// 0 = top of crop window, 1 = bottom. ~0.35 works well for face portraits.
  final double verticalFocus;
  final int dpi;

  IdPhotoOptions copyWith({
    IdPhotoBackground? background,
    double? verticalFocus,
    int? dpi,
  }) {
    return IdPhotoOptions(
      background: background ?? this.background,
      verticalFocus: verticalFocus ?? this.verticalFocus,
      dpi: dpi ?? this.dpi,
    );
  }
}
