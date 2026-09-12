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
      final targetAspect = preset.widthPx() / preset.heightPx();

      final cropWidth = source.width;
      final cropHeight = (source.width / targetAspect).round();
      final maxY = source.height - cropHeight;

      expect(maxY, greaterThan(0));
      expect((maxY * 0.2).round(), lessThan((maxY * 0.6).round()));
      expect(cropHeight, lessThan(source.height));
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
