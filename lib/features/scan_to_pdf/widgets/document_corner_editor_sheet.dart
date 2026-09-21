import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../shared/services/document_processing/document_boundary_detector.dart';
import '../models/scan_page.dart';
import '../providers/scan_session_provider.dart';

/// Manual corner adjustment fallback when auto detection is uncertain.
class DocumentCornerEditorSheet extends ConsumerStatefulWidget {
  const DocumentCornerEditorSheet({
    super.key,
    required this.page,
    required this.onDone,
  });

  final ScanPage page;
  final ValueChanged<ScanPage> onDone;

  static Future<ScanPage?> show(
    BuildContext context, {
    required ScanPage page,
  }) {
    return showModalBottomSheet<ScanPage>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      builder: (context) => DocumentCornerEditorSheet(
        page: page,
        onDone: (updated) => Navigator.pop(context, updated),
      ),
    );
  }

  @override
  ConsumerState<DocumentCornerEditorSheet> createState() =>
      _DocumentCornerEditorSheetState();
}

class _DocumentCornerEditorSheetState
    extends ConsumerState<DocumentCornerEditorSheet> {
  List<Offset> _corners = const [
    Offset(0.08, 0.08),
    Offset(0.92, 0.08),
    Offset(0.92, 0.92),
    Offset(0.08, 0.92),
  ];
  bool _processing = false;
  bool _cornersReady = false;

  @override
  void initState() {
    super.initState();
    _loadCorners();
  }

  Future<void> _loadCorners() async {
    final bytes = await File(widget.page.rawCapturePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null || widget.page.corners.length != 4) {
      if (mounted) setState(() => _cornersReady = true);
      return;
    }

    if (mounted) {
      setState(() {
        _corners = widget.page.corners
            .map(
              (c) => Offset(
                (c.x / decoded.width).clamp(0.02, 0.98),
                (c.y / decoded.height).clamp(0.02, 0.98),
              ),
            )
            .toList();
        _cornersReady = true;
      });
    }
  }

  void _resetCorners() {
    _loadCorners();
  }

  Future<void> _apply() async {
    setState(() => _processing = true);
    try {
      final bytes = await File(widget.page.rawCapturePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return;

      final docCorners = _corners
          .map(
            (c) => DocumentCorner(
              c.dx * decoded.width,
              c.dy * decoded.height,
            ),
          )
          .toList();

      final updated = await ref
          .read(scanSessionProvider.notifier)
          .reapplyGeometry(widget.page, docCorners);

      widget.onDone(updated);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Adjust Corners',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Drag the corners to match the document edges, then tap Apply.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 3 / 4,
            child: _cornersReady
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(widget.page.rawCapturePath),
                              fit: BoxFit.contain,
                            ),
                          ),
                          CustomPaint(
                            painter: _QuadPainter(_corners, w, h),
                            child: const SizedBox.expand(),
                          ),
                          for (var i = 0; i < _corners.length; i++)
                            Positioned(
                              left: _corners[i].dx * w - 14,
                              top: _corners[i].dy * h - 14,
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  setState(() {
                                    _corners[i] = Offset(
                                      (_corners[i].dx + details.delta.dx / w)
                                          .clamp(0.02, 0.98),
                                      (_corners[i].dy + details.delta.dy / h)
                                          .clamp(0.02, 0.98),
                                    );
                                  });
                                },
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        blurRadius: 4,
                                        color: Colors.black26,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton(
                onPressed: _processing ? null : _resetCorners,
                child: const Text('Reset'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _processing ? null : _apply,
                  child: _processing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuadPainter extends CustomPainter {
  const _QuadPainter(this.corners, this.width, this.height);

  final List<Offset> corners;
  final double width;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;

    final points = corners
        .map((c) => Offset(c.dx * width, c.dy * height))
        .toList();

    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blue.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _QuadPainter oldDelegate) =>
      oldDelegate.corners != corners;
}
