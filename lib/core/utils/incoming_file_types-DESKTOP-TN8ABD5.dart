import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum IncomingFileKind { pdf, image, word, excel, unsupported }

/// Detects supported incoming file types for Open with / Share flows.
class IncomingFileTypes {
  IncomingFileTypes._();

  static const _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'bmp',
    'gif',
    'heic',
    'heif',
  };

  static const _wordExtensions = {'doc', 'docx'};
  static const _excelExtensions = {'xls', 'xlsx'};

  static IncomingFileKind detect({
    required String path,
    String? mimeType,
  }) {
    final mime = (mimeType ?? '').toLowerCase();
    if (mime.contains('pdf')) return IncomingFileKind.pdf;
    if (mime.startsWith('image/')) return IncomingFileKind.image;
    if (mime.contains('msword') ||
        mime.contains('wordprocessingml')) {
      return IncomingFileKind.word;
    }
    if (mime.contains('ms-excel') || mime.contains('spreadsheetml')) {
      return IncomingFileKind.excel;
    }

    final ext = _extension(path);
    if (ext == 'pdf') return IncomingFileKind.pdf;
    if (_imageExtensions.contains(ext)) return IncomingFileKind.image;
    if (_wordExtensions.contains(ext)) return IncomingFileKind.word;
    if (_excelExtensions.contains(ext)) return IncomingFileKind.excel;
    return IncomingFileKind.unsupported;
  }

  static bool isSupported(IncomingFileKind kind) =>
      kind != IncomingFileKind.unsupported;

  static String label(IncomingFileKind kind) => switch (kind) {
        IncomingFileKind.pdf => 'PDF',
        IncomingFileKind.image => 'Image',
        IncomingFileKind.word => 'Word',
        IncomingFileKind.excel => 'Excel',
        IncomingFileKind.unsupported => 'File',
      };

  static IconData icon(IncomingFileKind kind) => switch (kind) {
        IncomingFileKind.pdf => Icons.picture_as_pdf_outlined,
        IncomingFileKind.image => Icons.image_outlined,
        IncomingFileKind.word => Icons.description_outlined,
        IncomingFileKind.excel => Icons.table_chart_outlined,
        IncomingFileKind.unsupported => Icons.insert_drive_file_outlined,
      };

  static Color accentColor(IncomingFileKind kind) => switch (kind) {
        IncomingFileKind.pdf => AppColors.electricBlue,
        IncomingFileKind.image => AppColors.green,
        IncomingFileKind.word => const Color(0xFF2563EB),
        IncomingFileKind.excel => const Color(0xFF16A34A),
        IncomingFileKind.unsupported =>
          AppColors.electricBlue.withValues(alpha: 0.7),
      };

  static String _extension(String path) {
    final name = path.split('/').last.split('\\').last;
    final dot = name.lastIndexOf('.');
    if (dot < 0) return '';
    return name.substring(dot + 1).toLowerCase();
  }
}
