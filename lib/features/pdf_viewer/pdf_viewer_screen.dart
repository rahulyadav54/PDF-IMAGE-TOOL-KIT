import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';

import '../../core/errors/app_exception.dart';
import '../../shared/services/file_actions_service.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  const PdfViewerScreen({
    super.key,
    required this.filePath,
    this.title,
  });

  final String filePath;
  final String? title;

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  late Future<List<int>> _pdfBytesFuture;

  @override
  void initState() {
    super.initState();
    _pdfBytesFuture = _loadPdfBytes();
  }

  Future<List<int>> _loadPdfBytes() async {
    final file = File(widget.filePath);
    if (!await file.exists()) {
      throw const InvalidFileException('PDF file is no longer available.');
    }
    return file.readAsBytes();
  }

  String get _displayTitle =>
      widget.title ?? p.basename(widget.filePath);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_outlined),
            onPressed: _share,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'external':
                  _openExternally();
                case 'download':
                  _saveToDownloads();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'external',
                child: Text('Open in another app'),
              ),
              PopupMenuItem(
                value: 'download',
                child: Text('Save to Downloads'),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<int>>(
        future: _pdfBytesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorBody(
              message: snapshot.error is AppException
                  ? (snapshot.error as AppException).message
                  : 'Unable to open this PDF.',
              onRetry: () {
                setState(() => _pdfBytesFuture = _loadPdfBytes());
              },
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          final bytes = snapshot.data!;
          if (bytes.isEmpty) {
            return const _ErrorBody(message: 'This PDF file is empty.');
          }

          return PdfPreview(
            build: (_) async => Uint8List.fromList(bytes),
            loadingWidget: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            pdfFileName: _displayTitle,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            allowPrinting: true,
            allowSharing: false,
            useActions: false,
            scrollViewDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
            ),
          );
        },
      ),
    );
  }

  Future<void> _share() async {
    try {
      await ref.read(fileActionsServiceProvider).shareFile(widget.filePath);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_errorMessage(error));
    }
  }

  Future<void> _openExternally() async {
    try {
      await ref.read(fileActionsServiceProvider).openFileExternally(widget.filePath);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_errorMessage(error));
    }
  }

  Future<void> _saveToDownloads() async {
    try {
      final result = await ref
          .read(fileActionsServiceProvider)
          .saveToDownloads(widget.filePath);
      if (!mounted) return;
      _showMessage(result.message);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_errorMessage(error));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorMessage(Object error) {
    if (error is AppException) return error.message;
    return 'Unable to complete this action. Please try again.';
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf_outlined, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
