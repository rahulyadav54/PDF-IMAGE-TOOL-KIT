import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_image_toolbox/features/id_photo/models/id_photo_options.dart';
import 'package:pdf_image_toolbox/features/id_photo/models/id_photo_preset.dart';

void main() {
  group('ID photo crop logic', () {
    test('portrait crop respects vertical focus', () {
      final source = img.Image(width: 1000, height: 1500);
      img.fill(source, color: img.ColorRgb8(200, 200, 200));

      final preset = IdPhotoPreset.presets.first;
      final targetW = preset.widthPx();
      final targetH = preset.heightPx();
      final aspect = targetW / targetH;

      final cropH = source.height;
      final cropW = (cropH * aspect).round();
      final maxY = source.height - cropH;

      final focusHigh = (maxY * 0.2).round();
      final focusLow = (maxY * 0.6).round();

      expect(focusHigh, lessThan(focusLow));
      expect(cropW, lessThan(source.width));
    });

    test('preset dimensions match 300 DPI mm conversion', () {
      const preset = IdPhotoPreset(
        id: 'test',
        name: 'Test',
        subtitle: 'Test',
        widthMm: 35,
        heightMm: 45,
      );
      expect(preset.widthPx(), 413);
      expect(preset.heightPx(), 531);
    });

    test('background options include white and original', () {
      expect(IdPhotoBackground.white.isOriginal, isFalse);
      expect(IdPhotoBackground.original.isOriginal, isTrue);
    });
  });
}
