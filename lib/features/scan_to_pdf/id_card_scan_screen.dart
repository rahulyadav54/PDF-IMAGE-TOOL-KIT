import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/models/tool_type.dart';
import '../../shared/providers/recent_files_provider.dart';
import '../../shared/services/file_actions_service.dart';
import '../../shared/services/recent_files_service.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/result_screen.dart';
import '../../shared/widgets/tool_app_bar_title.dart';
import '../scan_to_pdf/models/scan_enhance_kind.dart';
import '../scan_to_pdf/services/document_scanner_service.dart';
import '../scan_to_pdf/services/image_enhancement_service.dart';
import '../scan_to_pdf/services/scan_pdf_service.dart';

class IdCardScanScreen extends ConsumerStatefulWidget {
  const IdCardScanScreen({super.key});

  @override
  ConsumerState<IdCardScanScreen> createState() => _IdCardScanScreenState();
}

class _IdCardScanScreenState extends ConsumerState<IdCardScanScreen> {
  String? _frontPath;
  String? _backPath;
  bool _busy = false;

  Future<void> _scanFront() async {
    setState(() => _busy = true);
    try {
      final paths = await ref.read(documentScannerServiceProvider).scanMultiplePages();
      if (paths.isNotEmpty) {
        final enhanced = await ref.read(imageEnhancementServiceProvider).applyEnhancements(
              sourcePath: paths.first,
              kind: ScanEnhanceKind.document,
              preview: false,
            );
        setState(() => _frontPath = enhanced);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scanBack() async {
    setState(() => _busy = true);
    try {
      final paths = await ref.read(documentScannerServiceProvider).scanMultiplePages();
      if (paths.isNotEmpty) {
        final enhanced = await ref.read(imageEnhancementServiceProvider).applyEnhancements(
              sourcePath: paths.first,
              kind: ScanEnhanceKind.document,
              preview: false,
            );
        setState(() => _backPath = enhanced);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createPdf() async {
    final images = [_frontPath, _backPath].whereType<String>().toList();
    if (images.isEmpty) return;
    setState(() => _busy = true);
    try {
      final result = await ref.read(scanPdfServiceProvider).generatePdf(images);
      final entry = await ref.read(recentFilesServiceProvider).createEntry(
            filePath: result.outputPath,
            operation: 'ID Card PDF',
            fileSizeBytes: result.fileSizeBytes,
          );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: 'ID PDF Created',
            outputPath: result.outputPath,
            fileActions: ref.read(fileActionsServiceProvider),
            subtitle: result.fileName,
            pageCount: result.pageCount,
            onProcessAnother: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.idCardScanner)),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ScanSlot(label: 'FRONT', path: _frontPath, onScan: _scanFront),
                  const SizedBox(height: 16),
                  _ScanSlot(label: 'BACK', path: _backPath, onScan: _scanBack),
                  const Spacer(),
                  FilledButton(
                    onPressed: _frontPath == null ? null : _createPdf,
                    child: const Text('Create ID PDF'),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_busy) const LoadingOverlay(message: 'Processing...'),
      ],
    );
  }
}

class _ScanSlot extends StatelessWidget {
  const _ScanSlot({required this.label, required this.path, required this.onScan});

  final String label;
  final String? path;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (path != null) const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onScan, child: const Text('Scan')),
          ],
        ),
      ),
    );
  }
}
