import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/editor_models.dart';
import '../utils/pdf_coordinates.dart';
import 'annotation_painter.dart';
import 'text_overlay_painter.dart';

class PdfEditorCanvas extends StatefulWidget {
  const PdfEditorCanvas({
    super.key,
    required this.pageImage,
    required this.pageSize,
    required this.pageIndex,
    required this.textObjects,
    required this.textEdits,
    required this.newTexts,
    required this.annotations,
    required this.activeTool,
    required this.selectedTextId,
    required this.onTextTap,
    required this.onCanvasTap,
    required this.onAnnotationAdded,
    required this.onDrawPoints,
    this.previewTexts = const {},
  });

  final ui.Image? pageImage;
  final Size pageSize;
  final int pageIndex;
  final List<PdfTextObjectMetadata> textObjects;
  final Map<String, PdfTextEdit> textEdits;
  final List<PdfNewTextObject> newTexts;
  final List<PdfAnnotationObject> annotations;
  final PdfEditorTool activeTool;
  final String? selectedTextId;
  final ValueChanged<String> onTextTap;
  final ValueChanged<Offset> onCanvasTap;
  final ValueChanged<PdfAnnotationObject> onAnnotationAdded;
  final void Function(List<Offset> points, double scale) onDrawPoints;
  final Map<String, String> previewTexts;

  @override
  State<PdfEditorCanvas> createState() => _PdfEditorCanvasState();
}

class _PdfEditorCanvasState extends State<PdfEditorCanvas> {
  final TransformationController _transform = TransformationController();
  List<Offset> _currentStroke = [];

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayWidth = MediaQuery.sizeOf(context).width - 32;
    final scale = displayWidth / widget.pageSize.width;
    final displayHeight = widget.pageSize.height * scale;
    final showHitAreas = widget.activeTool == PdfEditorTool.text ||
        widget.activeTool == PdfEditorTool.select;

    return GestureDetector(
      onDoubleTap: () {
        final current = _transform.value.getMaxScaleOnAxis();
        _transform.value = Matrix4.identity()..scale(current > 1.2 ? 1.0 : 2.0);
      },
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 0.75,
        maxScale: 3,
        boundaryMargin: const EdgeInsets.all(48),
        child: Center(
          child: RepaintBoundary(
            child: SizedBox(
              width: displayWidth,
              height: displayHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) =>
                    _handleTap(details.localPosition, scale),
                onPanStart: _isDrawingTool
                    ? (details) => _currentStroke = [details.localPosition]
                    : null,
                onPanUpdate: _isDrawingTool
                    ? (details) => setState(
                          () => _currentStroke.add(details.localPosition),
                        )
                    : null,
                onPanEnd: _isDrawingTool
                    ? (_) {
                        if (_currentStroke.length >= 2) {
                          widget.onDrawPoints(_currentStroke, scale);
                        }
                        setState(() => _currentStroke = []);
                      }
                    : null,
                child: Stack(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.pageImage != null
                            ? RawImage(
                                image: widget.pageImage,
                                fit: BoxFit.fill,
                                width: displayWidth,
                                height: displayHeight,
                                filterQuality: FilterQuality.medium,
                              )
                            : const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                      ),
                    ),
                    CustomPaint(
                      size: Size(displayWidth, displayHeight),
                      painter: TextOverlayPainter(
                        textObjects: widget.textObjects,
                        textEdits: widget.textEdits,
                        newTexts: widget.newTexts,
                        pageIndex: widget.pageIndex,
                        scale: scale,
                        selectedTextId: widget.selectedTextId,
                        showHitAreas: showHitAreas,
                        previewTexts: widget.previewTexts,
                      ),
                    ),
                    CustomPaint(
                      size: Size(displayWidth, displayHeight),
                      painter: AnnotationPainter(
                        annotations: widget.annotations
                            .where((a) => a.pageIndex == widget.pageIndex)
                            .toList(),
                        scale: scale,
                        currentStroke: _currentStroke,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _isDrawingTool =>
      widget.activeTool == PdfEditorTool.draw ||
      widget.activeTool == PdfEditorTool.pen ||
      widget.activeTool == PdfEditorTool.highlight;

  void _handleTap(Offset local, double scale) {
    if (widget.activeTool == PdfEditorTool.text ||
        widget.activeTool == PdfEditorTool.select) {
      final hit = TextOverlayPainter.findTextAt(
        displayPoint: local,
        scale: scale,
        objects: widget.textObjects,
        edits: widget.textEdits,
      );
      if (hit != null) {
        widget.onTextTap(hit);
        return;
      }
    }

    if (widget.activeTool == PdfEditorTool.addText ||
        widget.activeTool == PdfEditorTool.signature ||
        widget.activeTool == PdfEditorTool.image) {
      widget.onCanvasTap(PdfCoordinates.fromDisplayPoint(local, scale));
      return;
    }

    if (widget.activeTool == PdfEditorTool.rectangle) {
      final pdfPoint = PdfCoordinates.fromDisplayPoint(local, scale);
      widget.onAnnotationAdded(
        PdfAnnotationObject(
          id: UniqueKey().toString(),
          pageIndex: widget.pageIndex,
          kind: AnnotationKind.rectangle,
          bounds: Rect.fromLTWH(pdfPoint.dx, pdfPoint.dy, 120, 60),
          color: const Color(0xFF1769FF),
          strokeWidth: 2,
        ),
      );
    }
  }
}
