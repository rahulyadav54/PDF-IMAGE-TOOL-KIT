import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/tool_type.dart';
import '../../shared/providers/recent_files_provider.dart';
import '../../shared/services/entitlement_service.dart';
import '../../shared/services/file_actions_service.dart';
import '../../shared/services/file_service.dart';
import '../../shared/services/recent_files_service.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/result_screen.dart';
import '../../shared/widgets/tool_app_bar_title.dart';
import 'services/pdf_redaction_service.dart';

class PdfRedactionScreen extends ConsumerStatefulWidget {
  const PdfRedactionScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<PdfRedactionScreen> createState() => _PdfRedactionScreenState();
}

class _PdfRedactionScreenState extends ConsumerState<PdfRedactionScreen> {
  String? _path;
  List<SensitiveMatch> _matches = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPath;
    if (initial != null && initial.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(initial));
    }
  }

  Future<void> _load(String path) async {
    setState(() => _busy = true);
    try {
      final matches =
          await ref.read(pdfRedactionServiceProvider).detectSensitiveInfo(path);
      if (mounted) {
        setState(() {
          _path = path;
          _matches = matches;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply() async {
    if (_path == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanent redaction'),
        content: const Text(
          'Permanent redaction cannot be undone after export. '
          'A new PDF will be created.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apply')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final canOperate = await ref.read(entitlementServiceProvider).canPerformOperation();
      if (!canOperate) throw const ProcessingException('Daily operation limit reached.');

      final result = await ref.read(pdfRedactionServiceProvider).applyRedactions(
            inputPath: _path!,
            matches: _matches,
            rasterizePages: true,
          );

      await ref.read(entitlementServiceProvider).recordOperation();
      final entry = await ref.read(recentFilesServiceProvider).createEntry(
            filePath: result.outputPath,
            operation: 'Redact PDF',
            fileSizeBytes: await ref.read(fileServiceProvider).getFileSize(result.outputPath),
          );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: 'Redaction Complete',
            outputPath: result.outputPath,
            fileActions: ref.read(fileActionsServiceProvider),
            subtitle: '${result.redactedCount} items redacted',
            onProcessAnother: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.pdfRedaction)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                if (_path == null)
                  FilledButton(
                    onPressed: () async {
                      final path = await ref
                          .read(fileServiceProvider)
                          .pickFile(allowedExtensions: ['pdf']);
                      if (path != null) _load(path);
                    },
                    child: const Text('Choose PDF'),
                  )
                else ...[
                  Text(
                    'Sensitive information found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ..._matches.map(
                    (m) => CheckboxListTile(
                      value: m.selected,
                      onChanged: (v) {
                        setState(() {
                          _matches = _matches
                              .map((x) => x.id == m.id ? x.copyWith(selected: v ?? false) : x)
                              .toList();
                        });
                      },
                      title: Text(m.label),
                      subtitle: Text('Page ${m.pageIndex + 1}: ${m.text}'),
                    ),
                  ),
                  if (_matches.isEmpty)
                    const Text('No sensitive patterns detected in extractable text.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy || _matches.isEmpty ? null : _apply,
                    child: const Text('Apply Permanent Redaction'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_busy) const LoadingOverlay(message: 'Applying redaction...'),
      ],
    );
  }
}
