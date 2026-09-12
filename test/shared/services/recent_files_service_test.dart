import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_image_toolbox/core/constants/app_constants.dart';
import 'package:pdf_image_toolbox/shared/models/recent_file.dart';
import 'package:pdf_image_toolbox/shared/services/recent_files_service.dart';

void main() {
  group('RecentFilesService.sanitize', () {
    RecentFile entry({
      required String id,
      required String path,
      DateTime? processedAt,
    }) {
      return RecentFile(
        id: id,
        fileName: path.split('/').last,
        filePath: path,
        fileType: 'PDF',
        operation: 'Test',
        processedAt: processedAt ?? DateTime(2025, 1, 1),
        fileSizeBytes: 100,
      );
    }

    test('removes duplicate paths keeping newest entry', () {
      final files = [
        entry(id: '1', path: '/out/a.pdf', processedAt: DateTime(2025, 1, 3)),
        entry(id: '2', path: '/out/a.pdf', processedAt: DateTime(2025, 1, 1)),
        entry(id: '3', path: '/out/b.pdf', processedAt: DateTime(2025, 1, 2)),
      ];

      final sanitized = RecentFilesService.sanitize(files);

      expect(sanitized.length, 2);
      expect(sanitized.first.id, '1');
      expect(sanitized.last.id, '3');
    });

    test('enforces maximum history size', () {
      final files = List.generate(
        AppConstants.maxRecentFiles + 5,
        (index) => entry(
          id: '$index',
          path: '/out/file_$index.pdf',
          processedAt: DateTime(2025, 1, index + 1),
        ),
      );

      final sanitized = RecentFilesService.sanitize(files);

      expect(sanitized.length, AppConstants.maxRecentFiles);
      expect(sanitized.first.id, '${AppConstants.maxRecentFiles + 4}');
    });

    test('skips entries with empty paths', () {
      final files = [
        entry(id: '1', path: ''),
        entry(id: '2', path: '/out/valid.pdf'),
      ];

      final sanitized = RecentFilesService.sanitize(files);

      expect(sanitized.length, 1);
      expect(sanitized.first.id, '2');
    });
  });
}
