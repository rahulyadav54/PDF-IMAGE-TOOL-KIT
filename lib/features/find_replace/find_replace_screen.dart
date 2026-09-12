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
import 'services/pdf_find_replace_service.dart';

class FindReplaceScreen extends ConsumerStatefulWidget {
  const FindReplaceScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<FindReplaceScreen> createState() => _FindReplaceScreenState();
}

class _FindReplaceScreenState extends ConsumerState<FindReplaceScreen> {
  String? _path;
  final _findController = TextEditingController();
  final _replaceController = TextEditingController();
  List<PdfTextMatch> _matches = [];
  bool _busy = false;
  TextOverflowFitMode _fitMode = TextOverflowFitMode.keepSize;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPath;
    if (initial != null && initial.isNotEmpty) _path = initial;
  }

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_path == null || _findController.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final matches = await ref.read(pdfFindReplaceServiceProvider).findAll(
            inputPath: _path!,
            query: _findController.text.trim(),
          );
      if (mounted) setState(() => _matches = matches);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _replaceAll() async {
    if (_path == null) return;
    setState(() => _busy = true);
    try {
      final canOperate = await ref.read(entitlementServiceProvider).canPerformOperation();
      if (!canOperate) throw const ProcessingException('Daily operation limit reached.');

      final result = await ref.read(pdfFindReplaceServiceProvider).replaceAll(
            inputPath: _path!,
            query: _findController.text.trim(),
            replacement: _replaceController.text,
            fitMode: _fitMode,
          );

      await ref.read(entitlementServiceProvider).recordOperation();
      final entry = await ref.read(recentFilesServiceProvider).createEntry(
            filePath: result.outputPath,
            operation: 'Find & Replace',
            fileSizeBytes: await ref.read(fileServiceProvider).getFileSize(result.outputPath),
          );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: 'Replace Complete',
            outputPath: result.outputPath,
            fileActions: ref.read(fileActionsServiceProvider),
            subtitle: '${result.replacementCount} replacements',
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
          appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.findReplace)),
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
                      if (path != null) setState(() => _path = path);
                    },
                    child: const Text('Choose PDF'),
                  )
                else ...[
                  TextField(
                    controller: _findController,
                    decoration: const InputDecoration(labelText: 'Find'),
                    onSubmitted: (_) => _search(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _replaceController,
                    decoration: const InputDecoration(labelText: 'Replace with'),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<TextOverflowFitMode>(
                    segments: const [
                      ButtonSegment(
                        value: TextOverflowFitMode.keepSize,
                        label: Text('Keep size'),
                      ),
                      ButtonSegment(
                        value: TextOverflowFitMode.fitText,
                        label: Text('Fit text'),
                      ),
                    ],
                    selected: {_fitMode},
                    onSelectionChanged: (s) => setState(() => _fitMode = s.first),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _search, child: const Text('Search')),
                  const SizedBox(height: 16),
                  Text('${_matches.length} matches'),
                  ..._matches.map(
                    (m) => ListTile(
                      dense: true,
                      title: Text(m.text),
                      subtitle: Text('Page ${m.pageIndex + 1}'),
                    ),
                  ),
                  if (_matches.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _busy ? null : _replaceAll,
                      child: const Text('Replace All'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        if (_busy) const LoadingOverlay(message: 'Replacing text...'),
      ],
    );
  }
}
