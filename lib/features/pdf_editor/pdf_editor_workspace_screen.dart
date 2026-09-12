import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/providers/recent_files_provider.dart';
import '../../shared/services/file_actions_service.dart';
import '../../shared/services/recent_files_service.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/result_screen.dart';
import 'models/editor_models.dart';
import 'providers/pdf_editor_session_provider.dart';
import 'services/pdf_editor_export_service.dart';
import 'services/pdf_ocr_service.dart';
import 'services/pdf_page_render_service.dart';
import 'utils/pdf_coordinates.dart';
import 'widgets/inline_text_editor.dart';
import 'widgets/pdf_editor_canvas.dart';
import 'widgets/pdf_editor_toolbar.dart';
import 'widgets/pdf_page_thumbnail_strip.dart';
import 'widgets/signature_sheet.dart';

class PdfEditorWorkspaceScreen extends ConsumerStatefulWidget {
  const PdfEditorWorkspaceScreen({super.key, this.signOnlyMode = false});

  final bool signOnlyMode;

  @override
  ConsumerState<PdfEditorWorkspaceScreen> createState() =>
      _PdfEditorWorkspaceScreenState();
}

class _PdfEditorWorkspaceScreenState
    extends ConsumerState<PdfEditorWorkspaceScreen> {
  static const _uuid = Uuid();

  ui.Image? _pageImage;
  bool _isExporting = false;
  String? _exportMessage;
  String _editingText = '';
  TextOverflowMode _overflowMode = TextOverflowMode.keepSize;

  @override
  void initState() {
    super.initState();
    _loadCurrentPageImage();
  }

  Future<void> _loadCurrentPageImage() async {
    final session = ref.read(pdfEditorSessionProvider);
    if (session == null || session.pages.isEmpty) return;

    try {
      final pageIndex = session.selectedPageIndex;
      if (pageIndex >= session.pages.length || pageIndex >= session.pageSizes.length) {
        return;
      }
      final sourceIndex = session.pages[pageIndex].sourceIndex ?? pageIndex;
      final image = await ref.read(pdfPageRenderServiceProvider).renderPage(
            pdfBytes: session.sourceBytes,
            pageIndex: sourceIndex,
          );
      if (mounted) setState(() => _pageImage = image);
    } catch (_) {
      if (mounted) setState(() => _pageImage = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(pdfEditorSessionProvider);
    final notifier = ref.read(pdfEditorSessionProvider.notifier);

    ref.listen<String?>(
      pdfEditorSessionProvider.select((s) => s?.selectedPageId),
      (previous, next) {
        if (previous != next) _loadCurrentPageImage();
      },
    );

    if (session == null) {
      return const Scaffold(
        body: Center(child: Text('No document loaded.')),
      );
    }

    final pageIndex = session.selectedPageIndex;
    final page = session.pages[pageIndex];
    final pageSize = session.pageSizes[pageIndex];
    final selectedText = session.selectedTextId != null
        ? session.textObjects[session.selectedTextId!]
        : null;
    final selectedEdit = session.selectedTextId != null
        ? session.textEdits[session.selectedTextId!]
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await _confirmLeave(session.isDirty);
        if (!context.mounted) return;
        if (leave) Navigator.of(context).pop();
      },
      child: Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            title: Text(
              widget.signOnlyMode ? 'Sign PDF' : session.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'rotate':
                      notifier.rotatePage(page.id);
                      _loadCurrentPageImage();
                    case 'duplicate':
                      notifier.duplicatePage(page.id);
                    case 'delete':
                      notifier.deletePage(page.id);
                      _loadCurrentPageImage();
                    case 'ocr':
                      _runOcr(pageIndex);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'rotate', child: Text('Rotate page')),
                  const PopupMenuItem(value: 'duplicate', child: Text('Duplicate page')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete page')),
                  if (session.documentKind != PdfDocumentKind.textBased)
                    const PopupMenuItem(
                      value: 'ocr',
                      child: Text('Make editable with OCR'),
                    ),
                ],
              ),
              IconButton(
                onPressed: () => _save(session, saveAsNew: true),
                icon: const Icon(Icons.save_outlined),
                tooltip: 'Save as',
              ),
              IconButton(
                onPressed: () => _showExportMenu(session),
                icon: const Icon(Icons.ios_share_rounded),
                tooltip: 'Export',
              ),
            ],
          ),
          body: Column(
            children: [
              if (session.documentKind == PdfDocumentKind.scanned &&
                  !session.ocrApplied)
                MaterialBanner(
                  content: const Text(
                    'This PDF appears to be scanned. Use OCR to make text editable.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => _runOcr(pageIndex),
                      child: const Text('Make Editable with OCR'),
                    ),
                  ],
                ),
              if (session.isLoadingText)
                const LinearProgressIndicator(minHeight: 2),
              if (session.isLoadingText)
                MaterialBanner(
                  content: const Text('Detecting editable text on this PDF...'),
                  leading: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  actions: const [SizedBox.shrink()],
                ),
              if (session.fontNotice != null)
                Container(
                  width: double.infinity,
                  color: AppColors.orange.withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    session.fontNotice!,
                    style: const TextStyle(fontSize: 12, color: AppColors.orange),
                  ),
                ),
              Expanded(
                child: PdfEditorCanvas(
                  pageImage: _pageImage,
                  pageSize: pageSize,
                  pageIndex: page.sourceIndex ?? pageIndex,
                  textObjects: session.textOnPage(page.sourceIndex ?? pageIndex),
                  textEdits: session.textEdits,
                  newTexts: session.newTexts,
                  annotations: session.annotations,
                  activeTool: session.activeTool,
                  selectedTextId: session.selectedTextId,
                  previewTexts: selectedText != null
                      ? {selectedText.id: _editingText}
                      : const {},
                  onTextTap: (id) {
                    notifier.selectText(id);
                    final edit = session.textEdits[id];
                    setState(() {
                      _editingText = edit?.currentText ?? '';
                      _overflowMode = edit?.overflowMode ?? TextOverflowMode.keepSize;
                    });
                  },
                  onCanvasTap: (pdfPoint) => _handleCanvasTap(session, pdfPoint),
                  onAnnotationAdded: notifier.addAnnotation,
                  onDrawPoints: (points, scale) =>
                      _handleDraw(session, points, pageIndex, scale),
                ),
              ),
              PdfPageThumbnailStrip(
                pages: session.pages,
                selectedPageId: session.selectedPageId,
                onPageSelected: (id) {
                  notifier.selectPage(id);
                  _loadCurrentPageImage();
                },
                onAddPage: notifier.addBlankPage,
              ),
              if (widget.signOnlyMode)
                Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'Tap on the page to place your signature, then tap Export to share.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                PdfEditorToolbar(
                  activeTool: session.activeTool,
                  canUndo: notifier.canUndo,
                  canRedo: notifier.canRedo,
                  onUndo: notifier.undo,
                  onRedo: notifier.redo,
                  onToolSelected: notifier.setTool,
                ),
            ],
          ),
        ),
        if (selectedText != null && selectedEdit != null)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.25),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: InlineTextEditor(
                    metadata: selectedText,
                    currentText: _editingText,
                    overflowMode: _overflowMode,
                    onChanged: (value) => setState(() => _editingText = value),
                    onOverflowModeChanged: (mode) => _overflowMode = mode,
                    onDelete: () {
                      notifier.deleteText(selectedText.id);
                      setState(() => _editingText = '');
                    },
                    onDone: () {
                      notifier.updateText(
                        selectedText.id,
                        _editingText,
                        overflow: _overflowMode,
                      );
                      notifier.setTool(PdfEditorTool.select);
                    },
                  ),
                ),
              ),
            ),
          ),
        if (_isExporting)
          LoadingOverlay(
            message: _exportMessage ?? 'Saving PDF...',
          ),
      ],
    ),
    );
  }

  Future<bool> _confirmLeave(bool isDirty) async {
    if (!isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave editor?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to close without saving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleCanvasTap(PdfEditorSessionState session, Offset pdfPoint) async {
    final notifier = ref.read(pdfEditorSessionProvider.notifier);
    final pageIndex = session.selectedPageIndex;
    final sourceIndex = session.pages[pageIndex].sourceIndex ?? pageIndex;

    switch (session.activeTool) {
      case PdfEditorTool.addText:
        await _addTextAt(sourceIndex, pdfPoint);
      case PdfEditorTool.signature:
        final bytes = await showModalBottomSheet<Uint8List>(
          context: context,
          isScrollControlled: true,
          builder: (context) => const SignatureSheet(),
        );
        if (bytes != null) {
          notifier.addSignature(
            PdfSignatureObject(
              id: _uuid.v4(),
              pageIndex: sourceIndex,
              imageBytes: bytes,
              bounds: Rect.fromLTWH(pdfPoint.dx, pdfPoint.dy, 160, 60),
              rotation: 0,
            ),
          );
        }
      case PdfEditorTool.image:
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        final bytes = result?.files.single.bytes;
        if (bytes != null) {
          notifier.addImage(
            PdfImageObject(
              id: _uuid.v4(),
              pageIndex: sourceIndex,
              imageBytes: bytes,
              bounds: Rect.fromLTWH(pdfPoint.dx, pdfPoint.dy, 140, 100),
              rotation: 0,
              isNew: true,
            ),
          );
        }
      default:
        break;
    }
  }

  Future<void> _addTextAt(int pageIndex, Offset pdfPoint) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add text'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter text'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty) return;
    ref.read(pdfEditorSessionProvider.notifier).addNewText(
          PdfNewTextObject(
            id: _uuid.v4(),
            pageIndex: pageIndex,
            text: text.trim(),
            bounds: Rect.fromLTWH(pdfPoint.dx, pdfPoint.dy, 220, 32),
            fontFamily: 'Helvetica',
            fontSize: 14,
            fontStyle: const [],
            color: const Color(0xFF0B1F4D),
            alignment: TextAlign.left,
            opacity: 1,
            rotation: 0,
            letterSpacing: 0,
          ),
        );
  }

  void _handleDraw(
    PdfEditorSessionState session,
    List<Offset> flutterPoints,
    int pageIndex,
    double scale,
  ) {
    final sourceIndex = session.pages[pageIndex].sourceIndex ?? pageIndex;
    final pdfPoints = flutterPoints
        .map((p) => PdfCoordinates.fromDisplayPoint(p, scale))
        .toList();

    final kind = session.activeTool == PdfEditorTool.highlight
        ? AnnotationKind.highlight
        : AnnotationKind.pen;

    ref.read(pdfEditorSessionProvider.notifier).addAnnotation(
          PdfAnnotationObject(
            id: _uuid.v4(),
            pageIndex: sourceIndex,
            kind: kind,
            bounds: _boundsFromPoints(pdfPoints),
            color: kind == AnnotationKind.highlight
                ? const Color(0xFFFFEB3B)
                : const Color(0xFF1769FF),
            strokeWidth: 2,
            points: pdfPoints,
            opacity: kind == AnnotationKind.highlight ? 0.45 : 1,
          ),
        );
  }

  Rect _boundsFromPoints(List<Offset> points) {
    var left = points.first.dx;
    var top = points.first.dy;
    var right = left;
    var bottom = top;
    for (final point in points) {
      left = left < point.dx ? left : point.dx;
      right = right > point.dx ? right : point.dx;
      top = top > point.dy ? top : point.dy;
      bottom = bottom < point.dy ? bottom : point.dy;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Future<void> _runOcr(int pageIndex) async {
    final session = ref.read(pdfEditorSessionProvider);
    if (session == null) return;

    setState(() {
      _isExporting = true;
      _exportMessage = 'Running OCR on page...';
    });

    try {
      final sourceIndex = session.pages[pageIndex].sourceIndex ?? pageIndex;
      final results = await ref.read(pdfOcrServiceProvider).recognizePage(
            pdfBytes: session.sourceBytes,
            pageIndex: sourceIndex,
            pageSize: session.pageSizes[pageIndex],
          );
      ref.read(pdfEditorSessionProvider.notifier).mergeOcrResults(results);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR found ${results.length} editable text regions.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OCR failed for this page.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportMessage = null;
        });
      }
    }
  }

  Future<void> _showExportMenu(PdfEditorSessionState session) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.save_outlined),
              title: const Text('Save as new PDF'),
              onTap: () => Navigator.pop(context, 'save_as'),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Export & share'),
              onTap: () => Navigator.pop(context, 'share'),
            ),
          ],
        ),
      ),
    );

    if (action == 'save_as') {
      await _save(session, saveAsNew: true);
    } else if (action == 'share') {
      final result = await _save(session, saveAsNew: true, navigate: false);
      if (result != null) {
        await ref.read(fileActionsServiceProvider).shareFile(result.outputPath);
      }
    }
  }

  Future<PdfEditorExportResult?> _save(
    PdfEditorSessionState session, {
    required bool saveAsNew,
    bool navigate = true,
  }) async {
    if (!saveAsNew) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Overwrite original?'),
          content: const Text(
            'Saving to the original file will replace it. Save as a new PDF instead?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Save as new'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Overwrite'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        return _save(session, saveAsNew: true, navigate: navigate);
      }
    }

    setState(() {
      _isExporting = true;
      _exportMessage = 'Exporting PDF...';
    });

    try {
      final exportService = ref.read(pdfEditorExportServiceProvider);
      final result = await Future(() => exportService.export(
            inputPath: session.sourcePath,
            sourceBytes: session.sourceBytes,
            pages: session.pages,
            textObjects: session.textObjects,
            textEdits: session.textEdits,
            newTexts: session.newTexts,
            images: session.images,
            deletedImageIds: session.deletedImageIds,
            annotations: session.annotations,
            signatures: session.signatures,
            password: session.password,
            saveAsNew: saveAsNew,
          ));

      final entry = await ref.read(recentFilesServiceProvider).createEntry(
            filePath: result.outputPath,
            operation: 'Edit PDF',
            fileSizeBytes: result.outputSizeBytes,
          );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (result.fontWarnings.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.fontWarnings.first)),
        );
      }

      if (!mounted) return result;
      if (navigate) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              title: 'PDF Saved',
              outputPath: result.outputPath,
              fileActions: ref.read(fileActionsServiceProvider),
              subtitle: result.fileName,
              newSizeBytes: result.outputSizeBytes,
              pageCount: result.pageCount,
              conversionLabel: 'PDF edited successfully',
              onProcessAnother: () {
                Navigator.of(context).pop();
                ref.read(pdfEditorSessionProvider.notifier).clear();
              },
            ),
          ),
        );
      }
      return result;
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
      return null;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save this PDF.')),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportMessage = null;
        });
      }
    }
  }
}
