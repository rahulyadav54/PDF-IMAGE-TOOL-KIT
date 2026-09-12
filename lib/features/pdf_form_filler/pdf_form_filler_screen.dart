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
import 'services/pdf_form_filler_service.dart';

class PdfFormFillerScreen extends ConsumerStatefulWidget {
  const PdfFormFillerScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<PdfFormFillerScreen> createState() => _PdfFormFillerScreenState();
}

class _PdfFormFillerScreenState extends ConsumerState<PdfFormFillerScreen> {
  String? _path;
  List<PdfFormFieldInfo> _fields = [];
  final _values = <int, String>{};
  bool _busy = false;

  Future<void> _load(String path) async {
    setState(() => _busy = true);
    try {
      final fields = await ref.read(pdfFormFillerServiceProvider).loadFields(path);
      if (!mounted) return;
      setState(() {
        _path = path;
        _fields = fields;
        for (final field in fields) {
          if (field.value != null) _values[field.index] = field.value!;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_path == null) return;
    setState(() => _busy = true);
    try {
      final canOperate = await ref.read(entitlementServiceProvider).canPerformOperation();
      if (!canOperate) throw const ProcessingException('Daily operation limit reached.');

      final result = await ref.read(pdfFormFillerServiceProvider).saveFilledForm(
            inputPath: _path!,
            values: _values,
          );

      await ref.read(entitlementServiceProvider).recordOperation();
      final entry = await ref.read(recentFilesServiceProvider).createEntry(
            filePath: result.outputPath,
            operation: 'Fill PDF Form',
            fileSizeBytes: result.outputSizeBytes,
          );
      await ref.read(recentFilesProvider.notifier).addEntry(entry);

      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            title: 'Form Saved',
            outputPath: result.outputPath,
            fileActions: ref.read(fileActionsServiceProvider),
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
          appBar: AppBar(title: const ToolAppBarTitle(tool: ToolType.pdfFormFiller)),
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
                    child: const Text('Choose PDF Form'),
                  )
                else if (_fields.isEmpty)
                  const Text('No AcroForm fields found in this PDF.')
                else ...[
                  ..._fields.map(
                    (field) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: field.name,
                          helperText: field.type,
                        ),
                        controller: TextEditingController(text: _values[field.index] ?? ''),
                        onChanged: (v) => _values[field.index] = v,
                        readOnly: field.isReadOnly,
                      ),
                    ),
                  ),
                  FilledButton(onPressed: _busy ? null : _save, child: const Text('Save Form')),
                ],
              ],
            ),
          ),
        ),
        if (_busy) const LoadingOverlay(message: 'Saving form...'),
      ],
    );
  }
}
