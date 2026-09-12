import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart' show FilePickerCancelledException, ProcessingException;
import '../../../shared/services/file_service.dart';
import '../../../shared/services/permission_service.dart';

final documentScannerServiceProvider =
    Provider<DocumentScannerService>((ref) => DocumentScannerService(ref));

/// Wraps native document scanning with edge detection and multi-page support.
class DocumentScannerService {
  DocumentScannerService(this._ref);

  final Ref _ref;

  /// Scans one page with camera or gallery.
  Future<String?> scanSinglePage() async {
    final paths = await _scan(maxPages: 1);
    if (paths.isEmpty) return null;
    return paths.first;
  }

  /// Scans multiple pages in one session (camera + gallery).
  Future<List<String>> scanMultiplePages() => _scan(
        maxPages: AppConstants.maxScanPages,
        source: ScannerSource.cameraAndGallery,
      );

  /// Picks multiple images from the gallery with document crop/adjustment.
  Future<List<String>> pickFromGalleryScanner() => _scan(
        maxPages: AppConstants.maxScanPages,
        source: ScannerSource.gallery,
        requestCamera: false,
      );

  /// Picks multiple image files directly (no native crop UI).
  Future<List<String>> pickImagesFromFiles() async {
    try {
      return await _ref.read(fileServiceProvider).pickMultipleFiles(
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      );
    } on FilePickerCancelledException {
      return [];
    } on Exception catch (e) {
      throw ProcessingException(
        'Unable to pick images. Please try again.',
        cause: e,
      );
    }
  }

  Future<List<String>> _scan({
    required int maxPages,
    ScannerSource source = ScannerSource.cameraAndGallery,
    bool requestCamera = true,
  }) async {
    if (requestCamera) {
      await _ref.read(permissionServiceProvider).requestCamera();
    }

    try {
      final paths = await CunningDocumentScanner.getPictures(
        noOfPages: maxPages,
        scannerSource: source,
        androidScannerMode: AndroidScannerMode.baseWithFilter,
      );

      if (paths == null || paths.isEmpty) return [];
      return paths;
    } on Exception catch (e) {
      throw ProcessingException(
        'Unable to scan documents. Please try again.',
        cause: e,
      );
    }
  }
}
