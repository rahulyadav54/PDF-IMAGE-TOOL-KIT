import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_image_toolbox/core/utils/path_security.dart';

void main() {
  group('PathSecurity', () {
    test('sanitizeFileName strips path segments and unsafe characters', () {
      expect(
        PathSecurity.sanitizeFileName('../../secret.pdf'),
        'secret.pdf',
      );
      expect(
        PathSecurity.sanitizeFileName('my:file?.pdf'),
        'my_file_.pdf',
      );
      expect(
        () => PathSecurity.sanitizeFileName('..'),
        throwsFormatException,
      );
    });

    test('outputPath stays within output directory', () {
      final outputDir = p.join('app', 'output');
      final path = PathSecurity.outputPath(outputDir, 'result.pdf');
      expect(p.basename(path), 'result.pdf');
      expect(p.isWithin(p.normalize(outputDir), p.normalize(path)), isTrue);
    });
  });
}
