import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/services/file_service.dart';

final pdfProtectServiceProvider =
    Provider<PdfProtectService>((ref) => PdfProtectService(ref));

class PdfProtectResult {
  const PdfProtectResult({
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

class PdfProtectService {
  PdfProtectService(this._ref);

  final Ref _ref;

  Future<PdfProtectResult> protect({
    required String inputPath,
    required String password,
    required int pageCount,
  }) async {
    if (password.length < 4) {
      throw const ProcessingException('Password must be at least 4 characters.');
    }

    final file = File(inputPath);
    if (!await file.exists()) {
      throw const InvalidFileException('PDF file no longer exists.');
    }

    final inputBytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: inputBytes);

    try {
      final security = document.security;
      security.userPassword = password;
      security.ownerPassword = password;
      security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;
      security.permissions.addAll([
        PdfPermissionsFlags.print,
        PdfPermissionsFlags.copyContent,
      ]);

      final outputBytes = Uint8List.fromList(await document.save());
      final fileName = FilenameGenerator.protectedPdf(inputPath);
      final outputPath =
          await _ref.read(fileServiceProvider).saveToOutput(fileName, outputBytes);

      return PdfProtectResult(
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
