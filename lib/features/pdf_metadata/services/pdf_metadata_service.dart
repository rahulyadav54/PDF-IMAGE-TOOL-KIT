import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/filename_generator.dart';
import '../../../shared/services/file_service.dart';

final pdfMetadataServiceProvider =
    Provider<PdfMetadataService>((ref) => PdfMetadataService(ref));

class PdfMetadataInfo {
  const PdfMetadataInfo({
    required this.title,
    required this.author,
    required this.subject,
    required this.keywords,
    required this.creator,
    required this.producer,
  });

  final String title;
  final String author;
  final String subject;
  final String keywords;
  final String creator;
  final String producer;
}

class PdfMetadataResult {
  const PdfMetadataResult({
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

class PdfMetadataService {
  PdfMetadataService(this._ref);

  final Ref _ref;

  Future<PdfMetadataInfo> read(String inputPath) async {
    final file = File(inputPath);
    if (!await file.exists()) {
      throw const InvalidFileException('PDF file no longer exists.');
    }

    final document = PdfDocument(inputBytes: await file.readAsBytes());
    try {
      final info = document.documentInformation;
      return PdfMetadataInfo(
        title: info.title,
        author: info.author,
        subject: info.subject,
        keywords: info.keywords,
        creator: info.creator,
        producer: info.producer,
      );
    } finally {
      document.dispose();
    }
  }

  Future<PdfMetadataResult> update({
    required String inputPath,
    required String title,
    required String author,
    required String subject,
    required String keywords,
    required int pageCount,
  }) async {
    final file = File(inputPath);
    if (!await file.exists()) {
      throw const InvalidFileException('PDF file no longer exists.');
    }

    final document = PdfDocument(inputBytes: await file.readAsBytes());
    try {
      final info = document.documentInformation;
      info.title = title;
      info.author = author;
      info.subject = subject;
      info.keywords = keywords;

      final outputBytes = Uint8List.fromList(await document.save());
      final fileName = FilenameGenerator.metadataPdf(inputPath);
      final outputPath = await _ref
          .read(fileServiceProvider)
          .saveToOutput(fileName, outputBytes);

      return PdfMetadataResult(
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
