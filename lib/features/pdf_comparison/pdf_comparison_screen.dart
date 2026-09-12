import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/models/tool_type.dart';
import '../../shared/services/file_service.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/tool_app_bar_title.dart';
import 'services/pdf_comparison_service.dart';

class PdfComparisonScreen extends ConsumerStatefulWidget {
  const PdfComparisonScreen({super.key});

  @override
  ConsumerState<PdfComparisonScreen> createState() => _PdfComparisonScreenState();
}

class _PdfComparisonScreenState extends ConsumerState<PdfComparisonScreen> {
  String? _originalPath;
  String? _modifiedPath;
  PdfComparisonReport? _report;
  bool _busy = false;

  Future<void> _compare() async {
    if (_originalPath == null || _modifiedPath == null) return;
    setState(() => _busy = true);
    try {
      final report = await ref.read(pdfComparisonServiceProvider).compare(
            originalPath: _originalPath!,
            modifiedPath: _modifiedPath!,
          );
      if (mounted) setState(() => _report = report);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.pdfComparison)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                OutlinedButton(
                  onPressed: () async {
                    final path = await ref
                        .read(fileServiceProvider)
                        .pickFile(allowedExtensions: ['pdf']);
                    if (path != null) setState(() => _originalPath = path);
                  },
                  child: Text(_originalPath == null ? 'Choose original PDF' : 'Original selected'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    final path = await ref
                        .read(fileServiceProvider)
                        .pickFile(allowedExtensions: ['pdf']);
                    if (path != null) setState(() => _modifiedPath = path);
                  },
                  child: Text(_modifiedPath == null ? 'Choose modified PDF' : 'Modified selected'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _compare,
                  child: const Text('Compare'),
                ),
                if (_report != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    '${_report!.modifiedCount} modified pages',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ..._report!.pageDiffs.map(
                    (diff) => ListTile(
                      dense: true,
                      leading: Icon(_iconFor(diff.kind)),
                      title: Text('Page ${diff.pageNumber} — ${_labelFor(diff.kind)}'),
                      subtitle: diff.visualDifferencePercent != null
                          ? Text('Visual diff ${diff.visualDifferencePercent!.toStringAsFixed(1)}%')
                          : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_busy) const LoadingOverlay(message: 'Comparing PDFs...'),
      ],
    );
  }

  IconData _iconFor(PdfPageDiffKind kind) {
    switch (kind) {
      case PdfPageDiffKind.unchanged:
        return Icons.check_circle_outline;
      case PdfPageDiffKind.modified:
        return Icons.edit_outlined;
      case PdfPageDiffKind.added:
        return Icons.add_circle_outline;
      case PdfPageDiffKind.removed:
        return Icons.remove_circle_outline;
    }
  }

  String _labelFor(PdfPageDiffKind kind) {
    switch (kind) {
      case PdfPageDiffKind.unchanged:
        return 'unchanged';
      case PdfPageDiffKind.modified:
        return 'modified';
      case PdfPageDiffKind.added:
        return 'added';
      case PdfPageDiffKind.removed:
        return 'removed';
    }
  }
}
