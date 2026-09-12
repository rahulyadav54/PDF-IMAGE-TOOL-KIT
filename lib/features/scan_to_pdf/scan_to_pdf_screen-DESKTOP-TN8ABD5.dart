import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../shared/services/bulk_processing/cancel_token.dart'
    show BulkCancelledException, CancelToken;
import '../../shared/widgets/bulk_processing_overlay.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/providers/recent_files_provider.dart';
import '../../shared/services/file_actions_service.dart';
import '../../shared/services/recent_files_service.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/providers/app_preferences_provider.dart';
import '../../shared/utils/workflow_presets.dart';
import '../../shared/widgets/result_screen.dart';
import 'models/scan_page.dart';
import 'providers/scan_session_provider.dart';
import 'services/document_scanner_service.dart';
import 'services/scan_pdf_service.dart';
import 'widgets/page_editor_sheet.dart';
import 'widgets/scan_pages_list.dart';

class ScanToPdfScreen extends ConsumerStatefulWidget {
  const ScanToPdfScreen({super.key});

  @override
  ConsumerState<ScanToPdfScreen> createState() => _ScanToPdfScreenState();
}

class _ScanToPdfScreenState extends ConsumerState<ScanToPdfScreen> {
  bool _isBusy = false;
  String? _busyMessage;
  CancelToken? _cancelToken;
  int _enhanceCurrent = 0;
  int _enhanceTotal = 0;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _runBusy(String message, Future<void> Function() action) async {
    setState(() {
      _isBusy = true;
      _busyMessage = message;
    });
    try {
      await action();
    } on AppException catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _busyMessage = null;
        });
      }
    }
  }

  Future<void> _addMultipleFromScanner() async {
    await _runBusy('Opening scanner...', () async {
      final paths = await ref.read(documentScannerServiceProvider).scanMultiplePages();
      if (paths.isEmpty) return;
      ref.read(scanSessionProvider.notifier).addPages(paths);
    });
  }

  Future<void> _addFromGallery() async {
    await _runBusy('Opening gallery...', () async {
      final paths = await ref.read(documentScannerServiceProvider).pickFromGalleryScanner();
      if (paths.isEmpty) return;
      ref.read(scanSessionProvider.notifier).addPages(paths);
    });
  }

  Future<void> _addFromFiles() async {
    await _runBusy('Selecting images...', () async {
      final paths = await ref.read(documentScannerServiceProvider).pickImagesFromFiles();
      if (paths.isEmpty) return;
      ref.read(scanSessionProvider.notifier).addPages(paths);
    });
  }

  Future<void> _enhanceAllPages() async {
    final pages = ref.read(scanSessionProvider);
    if (pages.isEmpty) return;

    _cancelToken = CancelToken();
    setState(() {
      _isBusy = true;
      _busyMessage = 'Enhancing pages...';
      _enhanceCurrent = 0;
      _enhanceTotal = pages.length;
    });

    try {
      await ref.read(scanSessionProvider.notifier).enhanceAllPages(
        onProgress: (current, total) {
          if (mounted) {
            setState(() {
              _enhanceCurrent = current;
              _enhanceTotal = total;
            });
          }
        },
        cancelToken: _cancelToken,
      );
      if (mounted) {
        _showSuccess('Magic Color applied — dim text is now clearer.');
      }
    } on BulkCancelledException {
      if (mounted) _showError('Enhancement cancelled.');
    } on AppException catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _busyMessage = null;
          _cancelToken = null;
        });
      }
    }
  }

  Future<void> _confirmCancelEnhance() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel processing?'),
        content: const Text('Enhancement will stop for remaining pages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (shouldCancel == true) _cancelToken?.cancel();
  }

  Future<void> _generatePdf() async {
    final pages = ref.read(scanSessionProvider);
    if (pages.isEmpty) return;

    await _runBusy('Creating PDF...', () async {
      final prefs = ref.read(appPreferencesProvider);
      final result = await ref.read(scanPdfServiceProvider).generatePdf(
        pages.map((p) => p.displayImagePath).toList(),
        maxImageWidth: prefs.scanMaxImageWidth,
        jpegQuality: prefs.scanJpegQuality,
      );

      final entry = await ref.read(recentFilesServiceProvider).createEntry(
        filePath: result.outputPath,
        operation: 'Scan to PDF',
        fileSizeBytes: result.fileSizeBytes,
      );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;
      await ref.read(scanSessionProvider.notifier).clear();
      if (!mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: 'PDF Created',
            outputPath: result.outputPath,
            fileActions: ref.read(fileActionsServiceProvider),
            subtitle: result.fileName,
            newSizeBytes: result.fileSizeBytes,
            pageCount: result.pageCount,
            workflowActions: WorkflowPresets.forScanResult(),
            onProcessAnother: () => Navigator.of(context).pop(),
          ),
        ),
      );
    });
  }

  void _openEditor(ScanPage page) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => PageEditorSheet(
        page: page,
        onSave: (updated) {
          ref.read(scanSessionProvider.notifier).updatePage(updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = ref.watch(scanSessionProvider);
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Scan Document'),
            actions: [
              if (pages.isNotEmpty)
                TextButton(
                  onPressed: _isBusy ? null : _generatePdf,
                  child: const Text('Save PDF'),
                ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: pages.isEmpty
                      ? _ScannerHero(onScan: _isBusy ? null : _addMultipleFromScanner)
                      : ListView(
                          padding: const EdgeInsets.all(AppSpacing.screenH),
                          children: [
                            Text(
                              '${pages.length} page${pages.length == 1 ? '' : 's'}',
                              style: AppTypography.sectionTitle(context),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ScanPagesList(
                              pages: pages,
                              onReorder: (old, newIndex) =>
                                  ref.read(scanSessionProvider.notifier).reorder(old, newIndex),
                              onTap: _openEditor,
                              onRemove: (page) =>
                                  ref.read(scanSessionProvider.notifier).removePage(page.id),
                            ),
                          ],
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.screenH),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    border: Border(top: BorderSide(color: scheme.outlineVariant)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _ControlButton(
                            icon: Icons.document_scanner_outlined,
                            label: 'Scan',
                            onTap: _isBusy ? null : _addMultipleFromScanner,
                            primary: true,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _ControlButton(
                            icon: Icons.photo_library_outlined,
                            label: 'Gallery',
                            onTap: _isBusy ? null : _addFromGallery,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _ControlButton(
                            icon: Icons.folder_open_outlined,
                            label: 'Files',
                            onTap: _isBusy ? null : _addFromFiles,
                          ),
                        ],
                      ),
                      if (pages.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isBusy ? null : _enhanceAllPages,
                                icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
                                label: const Text('Magic Color'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _isBusy ? null : _generatePdf,
                                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                                label: Text('Save PDF (${pages.length})'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isBusy && _busyMessage != null && _enhanceTotal > 0)
          BulkProcessingOverlay(
            title: 'Enhancing images',
            message: _busyMessage!,
            progress: _enhanceTotal > 0 ? _enhanceCurrent / _enhanceTotal : null,
            progressLabel: '$_enhanceCurrent / $_enhanceTotal images',
            detail: 'Improving text clarity...',
            onCancel: _confirmCancelEnhance,
          )
        else if (_isBusy && _busyMessage != null)
          LoadingOverlay(message: _busyMessage!),
      ],
    );
  }
}

class _ScannerHero extends StatelessWidget {
  const _ScannerHero({required this.onScan});

  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.document_scanner_outlined,
                    size: 72,
                    color: AppColors.electricBlue.withValues(alpha: 0.35),
                  ),
                  Positioned.fill(
                    child: CustomPaint(painter: _ScannerFramePainter()),
                  ),
                  Positioned(
                    bottom: 20,
                    child: Text(
                      'Position document within the frame',
                      style: AppTypography.caption(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Start scanning'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Auto edge detection • Crop • Enhance • Up to ${AppConstants.maxScanPages} pages',
            style: AppTypography.caption(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.electricBlue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const inset = 40.0;
    const corner = 28.0;
    final rect = Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2);

    void cornerPath(Offset start, Offset mid, Offset end) {
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(mid.dx, mid.dy)
        ..lineTo(end.dx, end.dy);
      canvas.drawPath(path, paint);
    }

    cornerPath(rect.topLeft, rect.topLeft + const Offset(corner, 0), rect.topLeft + Offset(0, corner));
    cornerPath(rect.topRight, rect.topRight + const Offset(-corner, 0), rect.topRight + Offset(0, corner));
    cornerPath(rect.bottomLeft, rect.bottomLeft + const Offset(corner, 0), rect.bottomLeft + Offset(0, -corner));
    cornerPath(rect.bottomRight, rect.bottomRight + const Offset(-corner, 0), rect.bottomRight + Offset(0, -corner));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: primary
            ? AppColors.electricBlue.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: primary ? AppColors.electricBlue : null,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primary ? AppColors.electricBlue : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
