import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/file_size_formatter.dart';
import '../models/tool_type.dart';
import '../services/file_service.dart';
import 'error_view.dart';
import 'tool_scaffold.dart';

/// Base entry screen for tools — Step 1: Select File.
/// Processing is implemented per-feature in later phases.
class ToolEntryScreen extends ConsumerStatefulWidget {
  const ToolEntryScreen({
    super.key,
    required this.tool,
    this.allowedExtensions,
    this.allowMultiple = false,
  });

  final ToolType tool;
  final List<String>? allowedExtensions;
  final bool allowMultiple;

  @override
  ConsumerState<ToolEntryScreen> createState() => _ToolEntryScreenState();
}

class _ToolEntryScreenState extends ConsumerState<ToolEntryScreen> {
  String? _selectedPath;
  int? _fileSize;
  String? _error;

  Future<void> _pickFile() async {
    setState(() {
      _error = null;
    });

    try {
      final fileService = ref.read(fileServiceProvider);
      if (widget.allowMultiple) {
        final paths = await fileService.pickMultipleFiles(
          allowedExtensions: widget.allowedExtensions,
        );
        if (paths.isNotEmpty) {
          setState(() {
            _selectedPath = paths.first;
          });
          final size = await fileService.getFileSize(_selectedPath!);
          setState(() => _fileSize = size);
        }
      } else {
        final path = await fileService.pickFile(
          allowedExtensions: widget.allowedExtensions,
        );
        if (path != null) {
          final size = await fileService.getFileSize(path);
          setState(() {
            _selectedPath = path;
            _fileSize = size;
          });
        }
      }
    } on AppException catch (e) {
      if (e is! FilePickerCancelledException) {
        setState(() => _error = e.message);
      }
    } catch (_) {
      setState(() => _error = 'Unable to select file. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ToolScaffold(
        title: widget.tool.title,
        body: ErrorView(
          message: _error!,
          onRetry: () {
            setState(() => _error = null);
            _pickFile();
          },
          onGoBack: () => Navigator.of(context).pop(),
        ),
      );
    }

    return ToolScaffold(
      title: widget.tool.title,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepIndicator(currentStep: 1, totalSteps: 4),
            const SizedBox(height: 24),
            Text(
              'Select File',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.tool.subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            if (_selectedPath != null) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(
                    ref.read(fileServiceProvider).getFileName(_selectedPath!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: _fileSize != null
                      ? Text(FileSizeFormatter.format(_fileSize!))
                      : null,
                ),
              ),
              const SizedBox(height: 16),
            ],
            FilledButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open_outlined),
              label: Text(_selectedPath == null ? 'Choose File' : 'Choose Another File'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(totalSteps, (index) {
        final step = index + 1;
        final isActive = step <= currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: isActive ? colors.primary : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
