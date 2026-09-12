import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/processing_job.dart';
import '../../shared/models/tool_type.dart';
import '../../shared/providers/recent_files_provider.dart';
import '../../shared/services/entitlement_service.dart';
import '../../shared/services/file_actions_service.dart';
import '../../shared/services/file_service.dart';
import '../../shared/services/pdf_validation_service.dart';
import '../../shared/services/recent_files_service.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/processing_screen.dart';
import '../../shared/widgets/result_screen.dart';
import '../../shared/widgets/step_bar.dart';
import '../../shared/widgets/tool_app_bar_title.dart';
import 'models/pdf_health_report.dart';
import 'services/pdf_fix_service.dart';
import 'services/pdf_health_analyzer_service.dart';

class FixMyPdfScreen extends ConsumerStatefulWidget {
  const FixMyPdfScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<FixMyPdfScreen> createState() => _FixMyPdfScreenState();
}

class _FixMyPdfScreenState extends ConsumerState<FixMyPdfScreen> {
  String? _path;
  PdfHealthReport? _report;
  bool _loading = false;
  bool _processing = false;
  ProcessingJob? _job;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPath;
    if (initial != null && initial.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pick(() async => initial));
    }
  }

  Future<void> _pick([Future<String?> Function()? load]) async {
    setState(() {
      _error = null;
      _report = null;
      _loading = true;
    });
    try {
      final path = load != null
          ? await load()
          : await ref.read(fileServiceProvider).pickFile(allowedExtensions: ['pdf']);
      if (path == null) return;
      await ref.read(pdfValidationServiceProvider).validate(path);
      setState(() => _path = path);
      await _analyze();
    } on AppException catch (e) {
      if (e is FilePickerCancelledException) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _analyze() async {
    if (_path == null) return;
    setState(() {
      _processing = true;
      _job = ProcessingJob(
        id: 'analyze',
        title: 'Analyzing document',
        type: 'fix_my_pdf',
        totalItems: 1,
        status: ProcessingStatus.processing,
      );
    });
    try {
      final report = await ref.read(pdfHealthAnalyzerServiceProvider).analyze(
            inputPath: _path!,
            onProgress: (c, t) {
              if (mounted) {
                setState(() {
                  _job = _job?.copyWith(
                    completedItems: c,
                    totalItems: t,
                    currentLabel: 'Analyzing page $c',
                  );
                });
              }
            },
          );
      if (mounted) setState(() => _report = report);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
          _job = null;
        });
      }
    }
  }

  Future<void> _fixAll() async {
    if (_path == null || _report == null) return;
    final fixes = _report!.fixableIssues();
    if (fixes.isEmpty) return;

    setState(() {
      _processing = true;
      _job = ProcessingJob(
        id: 'fix',
        title: 'Fixing PDF',
        type: 'fix_my_pdf',
        totalItems: _report!.pageCount,
        status: ProcessingStatus.processing,
      );
    });

    try {
      final canOperate = await ref.read(entitlementServiceProvider).canPerformOperation();
      if (!canOperate) throw const ProcessingException('Daily operation limit reached.');

      final result = await ref.read(pdfFixServiceProvider).applyFixes(
            inputPath: _path!,
            issuesToFix: fixes,
            onProgress: (c, t) {
              if (mounted) {
                setState(() {
                  _job = _job?.copyWith(
                    completedItems: c,
                    totalItems: t,
                    currentLabel: 'Applying fixes',
                  );
                });
              }
            },
          );

      await ref.read(entitlementServiceProvider).recordOperation();
      final entry = await ref.read(recentFilesServiceProvider).createEntry(
            filePath: result.outputPath,
            operation: 'Fix My PDF',
            fileSizeBytes: result.outputSizeBytes,
          );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: 'PDF Fixed',
            outputPath: result.outputPath,
            fileActions: ref.read(fileActionsServiceProvider),
            subtitle: '${result.fixesApplied} fixes applied',
            newSizeBytes: result.outputSizeBytes,
            pageCount: result.pageCount,
            onProcessAnother: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
          _job = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.fixMyPdf)),
        body: ErrorView(message: _error!, onRetry: () => setState(() => _error = null)),
      );
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.fixMyPdf)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                StepBar(currentStep: _report == null ? 1 : 2),
                const SizedBox(height: AppSpacing.lg),
                if (_path == null)
                  FilledButton.icon(
                    onPressed: _loading ? null : () => _pick(),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Choose PDF'),
                  )
                else if (_report != null) ...[
                  Text('Document health', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('${_report!.pageCount} pages • ${_report!.goodPageCount} good'),
                  const SizedBox(height: 16),
                  if (_report!.countFor(PdfPageIssueKind.rotated) > 0)
                    _IssueRow('${_report!.countFor(PdfPageIssueKind.rotated)} rotated'),
                  if (_report!.countFor(PdfPageIssueKind.largeBorders) > 0)
                    _IssueRow('${_report!.countFor(PdfPageIssueKind.largeBorders)} oversized borders'),
                  if (_report!.countFor(PdfPageIssueKind.lowContrast) > 0)
                    _IssueRow('${_report!.countFor(PdfPageIssueKind.lowContrast)} low contrast'),
                  if (_report!.countFor(PdfPageIssueKind.blurry) > 0)
                    _IssueRow('${_report!.countFor(PdfPageIssueKind.blurry)} blurry'),
                  if (_report!.countFor(PdfPageIssueKind.scanned) > 0)
                    _IssueRow('${_report!.countFor(PdfPageIssueKind.scanned)} scanned'),
                  const SizedBox(height: 20),
                  if (_report!.hasFixableIssues)
                    FilledButton(
                      onPressed: _processing ? null : _fixAll,
                      child: const Text('Fix All'),
                    ),
                ],
              ],
            ),
          ),
        ),
        if (_loading) const LoadingOverlay(message: 'Loading PDF...'),
        if (_processing && _job != null) ProcessingScreen(job: _job!),
      ],
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined, size: 18, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
