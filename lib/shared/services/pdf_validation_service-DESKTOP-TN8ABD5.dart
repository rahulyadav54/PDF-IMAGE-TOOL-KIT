import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../core/errors/app_exception.dart';

final pdfValidationServiceProvider =
    Provider<PdfValidationService>((ref) => PdfValidationService());

class PdfValidationResult {
  const PdfValidationResult({
    required this.pageCount,
    required this.fileSizeBytes,
    required this.fileName,
  });

  final int pageCount;
  final int fileSizeBytes;
  final String fileName;
}

/// Validates PDF files before processing.
class PdfValidationService {
  static const int maxFileSizeBytes = 150 * 1024 * 1024;

  Future<PdfValidationResult> validate(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const InvalidFileException('File no longer exists.');
    }

    final fileName = file.uri.pathSegments.last;
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      throw const InvalidFileException('Please select a valid PDF file.');
    }

    final size = await file.length();
    if (size == 0) {
      throw const InvalidFileException('This PDF file is empty.');
    }

    if (size > maxFileSizeBytes) {
      throw const ProcessingException(
        'This PDF is too large to process safely. Try a smaller file.',
      );
    }

    PdfDocument? document;
    try {
      final bytes = await file.readAsBytes();
      document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;

      if (pageCount == 0) {
        throw const InvalidFileException('This PDF has no pages.');
      }

      return PdfValidationResult(
        pageCount: pageCount,
        fileSizeBytes: size,
        fileName: fileName,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw const InvalidFileException(
        "We couldn't open this PDF. The file may be corrupted or unsupported.",
      );
    } finally {
      document?.dispose();
    }
  }
}
