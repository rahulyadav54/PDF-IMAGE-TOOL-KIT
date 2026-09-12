import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/services/file_service.dart';

final pdfUnlockServiceProvider =
    Provider<PdfUnlockService>((ref) => PdfUnlockService(ref));

class PdfUnlockResult {
  const PdfUnlockResult({
    required this.outputPath,
    required this.fileName,
    required this.outputSizeBytes,
    required this.pageCount,
  });

  final String outputPath;
  final String fileName;
  final int outputSizeBytes;
  final int pageCount;
}

class PdfUnlockService {
  PdfUnlockService(this._ref);

  final Ref _ref;

  Future<PdfUnlockResult> unlock({
    required String inputPath,
    required String password,
    required int pageCount,
  }) async {
    if (password.isEmpty) {
      throw const ProcessingException('Password is required.');
    }

    final file = File(inputPath);
    if (!await file.exists()) {
      throw const InvalidFileException('PDF file no longer exists.');
    }

    final inputBytes = await file.readAsBytes();
    PdfDocument? document;

    try {
      document = PdfDocument(inputBytes: inputBytes, password: password);
    } catch (_) {
      throw const ProcessingException(
        'Incorrect password or this PDF cannot be unlocked.',
      );
    }

    try {
      final outputBytes = Uint8List.fromList(await document.save());
      final fileName = FilenameGenerator.unlockedPdf(inputPath);
      final outputPath = await _ref
          .read(fileServiceProvider)
          .saveToOutput(fileName, outputBytes);

      return PdfUnlockResult(
        outputPath: outputPath,
        fileName: fileName,
        outputSizeBytes: outputBytes.length,
        pageCount: pageCount,
      );
    } finally {
      document.dispose();
    }
  }
}
