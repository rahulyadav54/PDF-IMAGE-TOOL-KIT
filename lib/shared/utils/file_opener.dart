import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/file_actions_service.dart';

/// Opens files in-app when supported, otherwise via the system viewer.
class FileOpener {
  FileOpener._();

  static Future<void> open(
    BuildContext context,
    String path, {
    required FileActionsService fileActions,
    String? title,
  }) async {
    if (fileActions.isPdf(path)) {
      if (!context.mounted) return;
      await context.push(
        '/pdf-viewer',
        extra: title == null ? path : {'path': path, 'title': title},
      );
      return;
    }

    await fileActions.openFileExternally(path);
  }
}

/// Parses route extra for the PDF viewer screen.
PdfViewerRouteData parsePdfViewerRoute(Object? extra) {
  if (extra is String) {
    return PdfViewerRouteData(filePath: extra);
  }
  if (extra is Map) {
    final path = extra['path'];
    final title = extra['title'];
    if (path is String) {
      return PdfViewerRouteData(
        filePath: path,
        title: title is String ? title : null,
      );
    }
  }
  return const PdfViewerRouteData(filePath: '');
}

bool isValidPdfViewerRoute(PdfViewerRouteData data) =>
    data.filePath.trim().isNotEmpty;

class PdfViewerRouteData {
  const PdfViewerRouteData({required this.filePath, this.title});

  final String filePath;
  final String? title;
}
