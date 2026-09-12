import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/documents/documents_screen.dart';
import '../features/open_with/open_with_screen.dart';
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
import '../features/extract_text/extract_text_screen.dart';
import '../features/pdf_metadata/pdf_metadata_screen.dart';
import '../features/sign_pdf/sign_pdf_screen.dart';
import '../features/searchable_pdf/searchable_pdf_screen.dart';
import '../features/unlock_pdf/unlock_pdf_screen.dart';
import '../features/pdf_watermark/pdf_watermark_screen.dart';
import '../features/workflows/workflows_screen.dart';
import '../features/vault/vault_screen.dart';
import '../features/protect_pdf/protect_pdf_screen.dart';
import '../features/pdf_page_editor/pdf_page_editor_screen.dart';
import '../features/pdf_editor/edit_pdf_screen.dart';
import '../features/id_photo/id_photo_screen.dart';
import '../features/image_stitch/image_stitch_screen.dart';
import '../features/image_watermark/image_watermark_screen.dart';
import '../features/image_filters/image_filters_screen.dart';
import '../features/clean_document/clean_document_screen.dart';
import '../features/fix_my_pdf/fix_my_pdf_screen.dart';
import '../features/find_replace/find_replace_screen.dart';
import '../features/pdf_redaction/pdf_redaction_screen.dart';
import '../features/pdf_form_filler/pdf_form_filler_screen.dart';
import '../features/pdf_comparison/pdf_comparison_screen.dart';
import '../features/scan_to_pdf/book_scan_screen.dart';
import '../features/scan_to_pdf/id_card_scan_screen.dart';
import '../features/scan_to_pdf/receipt_scan_screen.dart';
import '../features/scan_to_pdf/scan_to_pdf_screen.dart';
import '../features/pdf_viewer/pdf_viewer_screen.dart';
import '../features/privacy/privacy_screen.dart';
import '../features/privacy/terms_screen.dart';
import '../features/pro/pro_screen.dart';
import '../shared/utils/file_opener.dart';
import '../features/recent_files/recent_files_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tools_hub/tools_hub_screen.dart';
import '../shared/models/tool_type.dart';
import '../shared/services/open_with_service.dart';
import 'main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

String? _initialPath(GoRouterState state) {
  final extra = state.extra;
  return extra is String ? extra : null;
}

OpenWithFile? _openWithFile(GoRouterState state) {
  final extra = state.extra;
  if (extra is OpenWithFile) return extra;
  return null;
}

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Unavailable')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              'Unable to open this page.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please go back and try again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  ),
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomeScreen()),
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
      path: '/terms',
      builder: (context, state) => const TermsScreen(),
    ),
    GoRoute(
      path: '/pro',
      builder: (context, state) => const ProScreen(),
    ),
    GoRoute(
      path: '/pdf-viewer',
      builder: (context, state) {
        final data = parsePdfViewerRoute(state.extra);
        if (!isValidPdfViewerRoute(data)) {
          return Scaffold(
            appBar: AppBar(title: const Text('PDF Viewer')),
            body: const Center(
              child: Text('This file could not be opened.'),
            ),
          );
        }
        return PdfViewerScreen(
          filePath: data.filePath,
          title: data.title,
        );
      },
    ),
    GoRoute(
      path: '/open-with',
      builder: (context, state) {
        final file = _openWithFile(state);
        if (file == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Open With')),
            body: const Center(
              child: Text('Unable to open this file.'),
            ),
          );
        }
        return OpenWithScreen(file: file);
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
    GoRoute(
      path: ToolType.extractText.route,
      builder: (context, state) => ExtractTextScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.pdfMetadata.route,
      builder: (context, state) => PdfMetadataScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.signPdf.route,
      builder: (context, state) => SignPdfScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.searchablePdf.route,
      builder: (context, state) => SearchablePdfScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.unlockPdf.route,
      builder: (context, state) => UnlockPdfScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.pdfWatermark.route,
      builder: (context, state) => PdfWatermarkScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.workflows.route,
      builder: (context, state) => const WorkflowsScreen(),
    ),
    GoRoute(
      path: ToolType.secureVault.route,
      builder: (context, state) => const VaultScreen(),
    ),
    GoRoute(
      path: ToolType.cleanDocument.route,
      builder: (context, state) =>
          CleanDocumentScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.fixMyPdf.route,
      builder: (context, state) => FixMyPdfScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.findReplace.route,
      builder: (context, state) => FindReplaceScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.pdfRedaction.route,
      builder: (context, state) => PdfRedactionScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.pdfFormFiller.route,
      builder: (context, state) => PdfFormFillerScreen(initialPath: _initialPath(state)),
    ),
    GoRoute(
      path: ToolType.pdfComparison.route,
      builder: (context, state) => const PdfComparisonScreen(),
    ),
    GoRoute(
      path: ToolType.idCardScanner.route,
      builder: (context, state) => const IdCardScanScreen(),
    ),
    GoRoute(
      path: ToolType.receiptScanner.route,
      builder: (context, state) => const ReceiptScanScreen(),
    ),
    GoRoute(
      path: ToolType.bookScanner.route,
      builder: (context, state) => const BookScanScreen(),
    ),
  ],
);
