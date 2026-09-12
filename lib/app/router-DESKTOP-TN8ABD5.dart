import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/documents/documents_screen.dart';
import '../features/home/home_screen.dart';
import '../features/image_to_pdf/image_to_pdf_screen.dart';
import '../features/image_convert/image_convert_screen.dart';
import '../features/image_compress/image_compress_screen.dart';
import '../features/image_resize/image_resize_screen.dart';
import '../features/batch_processor/batch_processor_screen.dart';
import '../features/pdf_to_image/pdf_to_image_screen.dart';
import '../features/compress_pdf/compress_pdf_screen.dart';
import '../features/merge_pdf/merge_pdf_screen.dart';
import '../features/split_pdf/split_pdf_screen.dart';
import '../features/protect_pdf/protect_pdf_screen.dart';
import '../features/pdf_page_editor/pdf_page_editor_screen.dart';
import '../features/pdf_editor/edit_pdf_screen.dart';
import '../features/id_photo/id_photo_screen.dart';
import '../features/image_stitch/image_stitch_screen.dart';
import '../features/image_watermark/image_watermark_screen.dart';
import '../features/image_filters/image_filters_screen.dart';
import '../features/scan_to_pdf/scan_to_pdf_screen.dart';
import '../features/pdf_viewer/pdf_viewer_screen.dart';
import '../features/privacy/privacy_screen.dart';
import '../shared/utils/file_opener.dart';
import '../features/recent_files/recent_files_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tools_hub/tools_hub_screen.dart';
import '../shared/models/tool_type.dart';
import 'main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

String? _initialPath(GoRouterState state) {
  final extra = state.extra;
  return extra is String ? extra : null;
}

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/files',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DocumentsScreen()),
        ),
        GoRoute(
          path: '/documents',
          redirect: (_, __) => '/files',
        ),
        GoRoute(
          path: '/tools-hub',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ToolsHubScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/recent-files',
      builder: (context, state) => const RecentFilesScreen(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyScreen(),
    ),
    GoRoute(
      path: '/pdf-viewer',
      builder: (context, state) {
        final data = parsePdfViewerRoute(state.extra);
        return PdfViewerScreen(
          filePath: data.filePath,
          title: data.title,
        );
      },
    ),
    GoRoute(
      path: ToolType.scanToPdf.route,
      builder: (context, state) => const ScanToPdfScreen(),
    ),
    GoRoute(
      path: ToolType.compressPdf.route,
      builder: (context, state) => CompressPdfScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.mergePdf.route,
      builder: (context, state) => const MergePdfScreen(),
    ),
    GoRoute(
      path: ToolType.splitPdf.route,
      builder: (context, state) => SplitPdfScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.protectPdf.route,
      builder: (context, state) => ProtectPdfScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.pdfPageEditor.route,
      builder: (context, state) => PdfPageEditorScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.editPdf.route,
      builder: (context, state) => EditPdfScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.imageToPdf.route,
      builder: (context, state) => ImageToPdfScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.pdfToImage.route,
      builder: (context, state) => PdfToImageScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.idPhoto.route,
      builder: (context, state) => const IdPhotoScreen(),
    ),
    GoRoute(
      path: ToolType.imageStitch.route,
      builder: (context, state) => const ImageStitchScreen(),
    ),
    GoRoute(
      path: ToolType.imageConvert.route,
      builder: (context, state) => ImageConvertScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.imageCompress.route,
      builder: (context, state) => ImageCompressScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.imageResize.route,
      builder: (context, state) => ImageResizeScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.imageWatermark.route,
      builder: (context, state) => ImageWatermarkScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.imageFilters.route,
      builder: (context, state) => ImageFiltersScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.batchProcessor.route,
      builder: (context, state) => const BatchProcessorScreen(),
    ),
  ],
);
