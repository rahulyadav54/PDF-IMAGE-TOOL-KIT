import 'dart:ui';

import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Active tool in the PDF editor workspace.
enum PdfEditorTool {
  select,
  text,
  addText,
  image,
  draw,
  highlight,
  underline,
  strikethrough,
  pen,
  eraser,
  rectangle,
  circle,
  arrow,
  textBox,
  stickyNote,
  signature,
}

enum TextOverflowMode {
  keepSize,
  fitText,
  resizeText,
}

enum PdfDocumentKind {
  textBased,
  scanned,
  mixed,
}

enum AnnotationKind {
  highlight,
  underline,
  strikethrough,
  draw,
  pen,
  rectangle,
  circle,
  arrow,
  textBox,
  stickyNote,
}

/// Metadata captured from an existing PDF text object.
class PdfTextObjectMetadata {
  const PdfTextObjectMetadata({
    required this.id,
    required this.pageIndex,
    required this.originalText,
    required this.fontName,
    required this.fontFamily,
    required this.fontSize,
    required this.fontWeight,
    required this.fontStyle,
    required this.color,
    required this.characterSpacing,
    required this.lineSpacing,
    required this.alignment,
    required this.bounds,
    required this.rotation,
    this.isFromOcr = false,
    this.fontPreserved = true,
    this.fontNotice,
  });

  final String id;
  final int pageIndex;
  final String originalText;
  final String fontName;
  final String fontFamily;
  final double fontSize;
  final String fontWeight;
  final List<PdfFontStyle> fontStyle;
  final Color color;
  final double characterSpacing;
  final double lineSpacing;
  final TextAlign alignment;
  final Rect bounds;
  final double rotation;
  final bool isFromOcr;
  final bool fontPreserved;
  final String? fontNotice;

  PdfTextObjectMetadata copyWith({
    String? originalText,
    String? fontName,
    String? fontFamily,
    double? fontSize,
    String? fontWeight,
    List<PdfFontStyle>? fontStyle,
    Color? color,
    double? characterSpacing,
    double? lineSpacing,
    TextAlign? alignment,
    Rect? bounds,
    double? rotation,
    bool? isFromOcr,
    bool? fontPreserved,
    String? fontNotice,
  }) {
    return PdfTextObjectMetadata(
      id: id,
      pageIndex: pageIndex,
      originalText: originalText ?? this.originalText,
      fontName: fontName ?? this.fontName,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      color: color ?? this.color,
      characterSpacing: characterSpacing ?? this.characterSpacing,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      alignment: alignment ?? this.alignment,
      bounds: bounds ?? this.bounds,
      rotation: rotation ?? this.rotation,
      isFromOcr: isFromOcr ?? this.isFromOcr,
      fontPreserved: fontPreserved ?? this.fontPreserved,
      fontNotice: fontNotice ?? this.fontNotice,
    );
  }
}

/// User edit applied to an existing or OCR text object.
class PdfTextEdit {
  const PdfTextEdit({
    required this.id,
    required this.metadata,
    required this.currentText,
    this.overflowMode = TextOverflowMode.keepSize,
    this.isDeleted = false,
    this.editBounds,
  });

  final String id;
  final PdfTextObjectMetadata metadata;
  final String currentText;
  final TextOverflowMode overflowMode;
  final bool isDeleted;
  final Rect? editBounds;

  bool get isModified =>
      isDeleted || currentText != metadata.originalText || editBounds != null;

  PdfTextEdit copyWith({
    PdfTextObjectMetadata? metadata,
    String? currentText,
    TextOverflowMode? overflowMode,
    bool? isDeleted,
    Rect? editBounds,
    bool clearEditBounds = false,
  }) {
    return PdfTextEdit(
      id: id,
      metadata: metadata ?? this.metadata,
      currentText: currentText ?? this.currentText,
      overflowMode: overflowMode ?? this.overflowMode,
      isDeleted: isDeleted ?? this.isDeleted,
      editBounds: clearEditBounds ? null : (editBounds ?? this.editBounds),
    );
  }
}

/// New text placed by the user.
class PdfNewTextObject {
  const PdfNewTextObject({
    required this.id,
    required this.pageIndex,
    required this.text,
    required this.bounds,
    required this.fontFamily,
    required this.fontSize,
    required this.fontStyle,
    required this.color,
    required this.alignment,
    required this.opacity,
    required this.rotation,
    required this.letterSpacing,
    this.underline = false,
  });

  final String id;
  final int pageIndex;
  final String text;
  final Rect bounds;
  final String fontFamily;
  final double fontSize;
  final List<PdfFontStyle> fontStyle;
  final Color color;
  final TextAlign alignment;
  final double opacity;
  final double rotation;
  final double letterSpacing;
  final bool underline;

  PdfNewTextObject copyWith({
    String? text,
    Rect? bounds,
    String? fontFamily,
    double? fontSize,
    List<PdfFontStyle>? fontStyle,
    Color? color,
    TextAlign? alignment,
    double? opacity,
    double? rotation,
    double? letterSpacing,
    bool? underline,
  }) {
    return PdfNewTextObject(
      id: id,
      pageIndex: pageIndex,
      text: text ?? this.text,
      bounds: bounds ?? this.bounds,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontStyle: fontStyle ?? this.fontStyle,
      color: color ?? this.color,
      alignment: alignment ?? this.alignment,
      opacity: opacity ?? this.opacity,
      rotation: rotation ?? this.rotation,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      underline: underline ?? this.underline,
    );
  }
}

class PdfImageObject {
  const PdfImageObject({
    required this.id,
    required this.pageIndex,
    required this.imageBytes,
    required this.bounds,
    required this.rotation,
    this.isNew = false,
    this.sourceObjectId,
  });

  final String id;
  final int pageIndex;
  final List<int> imageBytes;
  final Rect bounds;
  final double rotation;
  final bool isNew;
  final String? sourceObjectId;

  PdfImageObject copyWith({
    List<int>? imageBytes,
    Rect? bounds,
    double? rotation,
    bool? isDeleted,
  }) {
    return PdfImageObject(
      id: id,
      pageIndex: pageIndex,
      imageBytes: imageBytes ?? this.imageBytes,
      bounds: bounds ?? this.bounds,
      rotation: rotation ?? this.rotation,
      isNew: isNew,
      sourceObjectId: sourceObjectId,
    );
  }
}

class PdfAnnotationObject {
  const PdfAnnotationObject({
    required this.id,
    required this.pageIndex,
    required this.kind,
    required this.bounds,
    required this.color,
    required this.strokeWidth,
    this.points = const [],
    this.text,
    this.opacity = 1,
  });

  final String id;
  final int pageIndex;
  final AnnotationKind kind;
  final Rect bounds;
  final Color color;
  final double strokeWidth;
  final List<Offset> points;
  final String? text;
  final double opacity;
}

class PdfSignatureObject {
  const PdfSignatureObject({
    required this.id,
    required this.pageIndex,
    required this.imageBytes,
    required this.bounds,
    required this.rotation,
  });

  final String id;
  final int pageIndex;
  final List<int> imageBytes;
  final Rect bounds;
  final double rotation;
}

class PdfEditorPage {
  const PdfEditorPage({
    required this.id,
    required this.sourceIndex,
    required this.rotationSteps,
    this.isDeleted = false,
  });

  final String id;
  final int? sourceIndex;
  final int rotationSteps;
  final bool isDeleted;

  PdfPageRotateAngle get rotationAngle {
    switch (rotationSteps % 4) {
      case 0:
        return PdfPageRotateAngle.rotateAngle0;
      case 1:
        return PdfPageRotateAngle.rotateAngle90;
      case 2:
        return PdfPageRotateAngle.rotateAngle180;
      case 3:
        return PdfPageRotateAngle.rotateAngle270;
      default:
        return PdfPageRotateAngle.rotateAngle0;
    }
  }

  PdfEditorPage copyWith({
    int? sourceIndex,
    int? rotationSteps,
    bool? isDeleted,
  }) {
    return PdfEditorPage(
      id: id,
      sourceIndex: sourceIndex ?? this.sourceIndex,
      rotationSteps: rotationSteps ?? this.rotationSteps,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

/// Snapshot for undo/redo.
class PdfEditorSnapshot {
  const PdfEditorSnapshot({
    required this.pages,
    required this.textEdits,
    required this.newTexts,
    required this.images,
    required this.deletedImageIds,
    required this.annotations,
    required this.signatures,
    required this.selectedPageId,
  });

  final List<PdfEditorPage> pages;
  final Map<String, PdfTextEdit> textEdits;
  final List<PdfNewTextObject> newTexts;
  final List<PdfImageObject> images;
  final Set<String> deletedImageIds;
  final List<PdfAnnotationObject> annotations;
  final List<PdfSignatureObject> signatures;
  final String? selectedPageId;
}

class PdfEditorExportResult {
  const PdfEditorExportResult({
    required this.outputPath,
    required this.fileName,
    required this.outputSizeBytes,
    required this.pageCount,
    required this.fontWarnings,
  });

  final String outputPath;
  final String fileName;
  final int outputSizeBytes;
  final int pageCount;
  final List<String> fontWarnings;
}
