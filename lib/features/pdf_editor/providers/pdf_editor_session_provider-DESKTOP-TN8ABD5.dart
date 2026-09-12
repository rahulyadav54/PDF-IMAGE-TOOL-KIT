import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';

import '../models/editor_models.dart';
import '../services/pdf_scanned_detection_service.dart';
import '../services/pdf_text_extraction_service.dart';

const _uuid = Uuid();

class PdfEditorSessionState {
  const PdfEditorSessionState({
    required this.sourcePath,
    required this.sourceBytes,
    required this.fileName,
    required this.pages,
    required this.pageSizes,
    required this.textObjects,
    required this.textEdits,
    required this.newTexts,
    required this.images,
    required this.deletedImageIds,
    required this.annotations,
    required this.signatures,
    required this.documentKind,
    required this.activeTool,
    this.selectedPageId,
    this.selectedTextId,
    this.selectedObjectId,
    this.password,
    this.isDirty = false,
    this.ocrApplied = false,
    this.fontNotice,
    this.isLoadingText = false,
  });

  final String sourcePath;
  final Uint8List sourceBytes;
  final String fileName;
  final List<PdfEditorPage> pages;
  final List<Size> pageSizes;
  final Map<String, PdfTextObjectMetadata> textObjects;
  final Map<String, PdfTextEdit> textEdits;
  final List<PdfNewTextObject> newTexts;
  final List<PdfImageObject> images;
  final Set<String> deletedImageIds;
  final List<PdfAnnotationObject> annotations;
  final List<PdfSignatureObject> signatures;
  final PdfDocumentKind documentKind;
  final PdfEditorTool activeTool;
  final String? selectedPageId;
  final String? selectedTextId;
  final String? selectedObjectId;
  final String? password;
  final bool isDirty;
  final bool ocrApplied;
  final String? fontNotice;
  final bool isLoadingText;

  int get selectedPageIndex {
    if (pages.isEmpty) return 0;
    if (selectedPageId == null) return 0;
    final index = pages.indexWhere((p) => p.id == selectedPageId);
    if (index < 0) return 0;
    return index;
  }

  PdfEditorPage? get selectedPage {
    if (selectedPageId == null) return pages.isNotEmpty ? pages.first : null;
    return pages.cast<PdfEditorPage?>().firstWhere(
          (p) => p?.id == selectedPageId,
          orElse: () => pages.isNotEmpty ? pages.first : null,
        );
  }

  List<PdfTextObjectMetadata> textOnPage(int pageIndex) {
    return textObjects.values
        .where((t) => t.pageIndex == pageIndex)
        .toList();
  }

  PdfEditorSessionState copyWith({
    String? sourcePath,
    Uint8List? sourceBytes,
    String? fileName,
    List<PdfEditorPage>? pages,
    List<Size>? pageSizes,
    Map<String, PdfTextObjectMetadata>? textObjects,
    Map<String, PdfTextEdit>? textEdits,
    List<PdfNewTextObject>? newTexts,
    List<PdfImageObject>? images,
    Set<String>? deletedImageIds,
    List<PdfAnnotationObject>? annotations,
    List<PdfSignatureObject>? signatures,
    PdfDocumentKind? documentKind,
    PdfEditorTool? activeTool,
    String? selectedPageId,
    String? selectedTextId,
    String? selectedObjectId,
    String? password,
    bool? isDirty,
    bool? ocrApplied,
    String? fontNotice,
    bool? isLoadingText,
    bool clearSelectedText = false,
    bool clearSelectedObject = false,
  }) {
    return PdfEditorSessionState(
      sourcePath: sourcePath ?? this.sourcePath,
      sourceBytes: sourceBytes ?? this.sourceBytes,
      fileName: fileName ?? this.fileName,
      pages: pages ?? this.pages,
      pageSizes: pageSizes ?? this.pageSizes,
      textObjects: textObjects ?? this.textObjects,
      textEdits: textEdits ?? this.textEdits,
      newTexts: newTexts ?? this.newTexts,
      images: images ?? this.images,
      deletedImageIds: deletedImageIds ?? this.deletedImageIds,
      annotations: annotations ?? this.annotations,
      signatures: signatures ?? this.signatures,
      documentKind: documentKind ?? this.documentKind,
      activeTool: activeTool ?? this.activeTool,
      selectedPageId: selectedPageId ?? this.selectedPageId,
      selectedTextId:
          clearSelectedText ? null : (selectedTextId ?? this.selectedTextId),
      selectedObjectId: clearSelectedObject
          ? null
          : (selectedObjectId ?? this.selectedObjectId),
      password: password ?? this.password,
      isDirty: isDirty ?? this.isDirty,
      ocrApplied: ocrApplied ?? this.ocrApplied,
      fontNotice: fontNotice ?? this.fontNotice,
      isLoadingText: isLoadingText ?? this.isLoadingText,
    );
  }

  PdfEditorSnapshot toSnapshot() {
    return PdfEditorSnapshot(
      pages: List.of(pages),
      textEdits: Map.of(textEdits),
      newTexts: List.of(newTexts),
      images: List.of(images),
      deletedImageIds: Set.of(deletedImageIds),
      annotations: List.of(annotations),
      signatures: List.of(signatures),
      selectedPageId: selectedPageId,
    );
  }

  factory PdfEditorSessionState.fromSnapshot(
    PdfEditorSnapshot snapshot, {
    required PdfEditorSessionState base,
  }) {
    return base.copyWith(
      pages: snapshot.pages,
      textEdits: snapshot.textEdits,
      newTexts: snapshot.newTexts,
      images: snapshot.images,
      deletedImageIds: snapshot.deletedImageIds,
      annotations: snapshot.annotations,
      signatures: snapshot.signatures,
      selectedPageId: snapshot.selectedPageId,
      isDirty: true,
    );
  }
}

class PdfEditorSessionNotifier extends StateNotifier<PdfEditorSessionState?> {
  PdfEditorSessionNotifier(this._ref) : super(null);

  final Ref _ref;
  final List<PdfEditorSnapshot> _undoStack = [];
  final List<PdfEditorSnapshot> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  Future<void> loadDocument({
    required String path,
    required Uint8List bytes,
    required String fileName,
    String? password,
  }) async {
    final document = PdfDocument(inputBytes: bytes, password: password);
    try {
      final pageSizes = <Size>[];
      final pages = <PdfEditorPage>[];

      for (var i = 0; i < document.pages.count; i++) {
        final size = document.pages[i].getClientSize();
        pageSizes.add(size);
        pages.add(PdfEditorPage(id: _uuid.v4(), sourceIndex: i, rotationSteps: 0));
      }

      final kind =
          _ref.read(pdfScannedDetectionServiceProvider).detect(document);

      state = PdfEditorSessionState(
        sourcePath: path,
        sourceBytes: bytes,
        fileName: fileName,
        pages: pages,
        pageSizes: pageSizes,
        textObjects: const {},
        textEdits: const {},
        newTexts: const [],
        images: const [],
        deletedImageIds: {},
        annotations: const [],
        signatures: const [],
        documentKind: kind,
        activeTool: PdfEditorTool.select,
        selectedPageId: pages.isNotEmpty ? pages.first.id : null,
        password: password,
        isLoadingText: true,
      );

      _undoStack.clear();
      _redoStack.clear();
    } finally {
      document.dispose();
    }

    final textObjectsList = await Future(() {
      final doc = PdfDocument(inputBytes: bytes, password: password);
      try {
        return _ref.read(pdfTextExtractionServiceProvider).extractTextObjects(doc);
      } finally {
        doc.dispose();
      }
    });

    final textObjects = {for (final t in textObjectsList) t.id: t};
    final textEdits = <String, PdfTextEdit>{};
    for (final object in textObjectsList) {
      textEdits[object.id] = PdfTextEdit(
        id: object.id,
        metadata: object,
        currentText: object.originalText,
      );
    }

    if (state == null) return;
    state = state!.copyWith(
      textObjects: textObjects,
      textEdits: textEdits,
      isLoadingText: false,
    );
  }

  void _pushUndo() {
    if (state == null) return;
    _undoStack.add(state!.toSnapshot());
    _redoStack.clear();
    if (_undoStack.length > 50) _undoStack.removeAt(0);
  }

  void undo() {
    if (state == null || _undoStack.isEmpty) return;
    _redoStack.add(state!.toSnapshot());
    final previous = _undoStack.removeLast();
    state = PdfEditorSessionState.fromSnapshot(previous, base: state!);
  }

  void redo() {
    if (state == null || _redoStack.isEmpty) return;
    _undoStack.add(state!.toSnapshot());
    final next = _redoStack.removeLast();
    state = PdfEditorSessionState.fromSnapshot(next, base: state!);
  }

  void setTool(PdfEditorTool tool) {
    if (state == null) return;
    state = state!.copyWith(
      activeTool: tool,
      clearSelectedText: true,
      clearSelectedObject: true,
    );
  }

  void selectPage(String pageId) {
    if (state == null) return;
    state = state!.copyWith(
      selectedPageId: pageId,
      clearSelectedText: true,
      clearSelectedObject: true,
    );
  }

  void selectText(String textId) {
    if (state == null) return;
    state = state!.copyWith(
      selectedTextId: textId,
      activeTool: PdfEditorTool.text,
    );
  }

  void updateText(String textId, String newText, {TextOverflowMode? overflow}) {
    if (state == null) return;
    _pushUndo();
    final edit = state!.textEdits[textId];
    if (edit == null) return;

    final updated = edit.copyWith(
      currentText: newText,
      overflowMode: overflow ?? edit.overflowMode,
    );

    final edits = Map<String, PdfTextEdit>.of(state!.textEdits);
    edits[textId] = updated;
    state = state!.copyWith(textEdits: edits, isDirty: true);
  }

  void deleteText(String textId) {
    if (state == null) return;
    _pushUndo();
    final edit = state!.textEdits[textId];
    if (edit == null) return;
    final edits = Map<String, PdfTextEdit>.of(state!.textEdits);
    edits[textId] = edit.copyWith(isDeleted: true, currentText: '');
    state = state!.copyWith(textEdits: edits, isDirty: true, clearSelectedText: true);
  }

  void addNewText(PdfNewTextObject text) {
    if (state == null) return;
    _pushUndo();
    state = state!.copyWith(
      newTexts: [...state!.newTexts, text],
      isDirty: true,
    );
  }

  void updateNewText(String id, PdfNewTextObject updated) {
    if (state == null) return;
    final texts = state!.newTexts.map((text) {
      return text.id == id ? updated : text;
    }).toList();
    state = state!.copyWith(newTexts: texts, isDirty: true);
  }

  void addAnnotation(PdfAnnotationObject annotation) {
    if (state == null) return;
    _pushUndo();
    state = state!.copyWith(
      annotations: [...state!.annotations, annotation],
      isDirty: true,
    );
  }

  void addSignature(PdfSignatureObject signature) {
    if (state == null) return;
    _pushUndo();
    state = state!.copyWith(
      signatures: [...state!.signatures, signature],
      isDirty: true,
    );
  }

  void addImage(PdfImageObject image) {
    if (state == null) return;
    _pushUndo();
    state = state!.copyWith(
      images: [...state!.images, image],
      isDirty: true,
    );
  }

  void rotatePage(String pageId) {
    if (state == null) return;
    _pushUndo();
    final pages = state!.pages.map((page) {
      if (page.id != pageId) return page;
      return page.copyWith(rotationSteps: page.rotationSteps + 1);
    }).toList();
    state = state!.copyWith(pages: pages, isDirty: true);
  }

  void deletePage(String pageId) {
    if (state == null) return;
    final active = state!.pages.where((p) => !p.isDeleted).length;
    if (active <= 1) return;
    _pushUndo();
    final pages = state!.pages.map((page) {
      if (page.id != pageId) return page;
      return page.copyWith(isDeleted: true);
    }).toList();
    final nextPage = pages.firstWhere((p) => !p.isDeleted);
    state = state!.copyWith(
      pages: pages,
      selectedPageId: nextPage.id,
      isDirty: true,
    );
  }

  void duplicatePage(String pageId) {
    if (state == null) return;
    _pushUndo();
    final index = state!.pages.indexWhere((p) => p.id == pageId);
    if (index < 0) return;
    final source = state!.pages[index];
    final duplicate = PdfEditorPage(
      id: _uuid.v4(),
      sourceIndex: source.sourceIndex,
      rotationSteps: source.rotationSteps,
    );
    final pages = List<PdfEditorPage>.of(state!.pages);
    pages.insert(index + 1, duplicate);
    state = state!.copyWith(pages: pages, isDirty: true, selectedPageId: duplicate.id);
  }

  void addBlankPage() {
    if (state == null) return;
    _pushUndo();
    final page = PdfEditorPage(id: _uuid.v4(), sourceIndex: null, rotationSteps: 0);
    final pages = [...state!.pages, page];
    final sizes = [...state!.pageSizes, const Size(595, 842)];
    state = state!.copyWith(
      pages: pages,
      pageSizes: sizes,
      selectedPageId: page.id,
      isDirty: true,
    );
  }

  void reorderPage(int oldIndex, int newIndex) {
    if (state == null) return;
    _pushUndo();
    final pages = List<PdfEditorPage>.of(state!.pages);
    if (newIndex > oldIndex) newIndex -= 1;
    final page = pages.removeAt(oldIndex);
    pages.insert(newIndex, page);
    state = state!.copyWith(pages: pages, isDirty: true);
  }

  void mergeOcrResults(List<PdfTextObjectMetadata> ocrObjects) {
    if (state == null) return;
    _pushUndo();
    final textObjects = Map<String, PdfTextObjectMetadata>.of(state!.textObjects);
    final textEdits = Map<String, PdfTextEdit>.of(state!.textEdits);

    for (final object in ocrObjects) {
      textObjects[object.id] = object;
      textEdits[object.id] = PdfTextEdit(
        id: object.id,
        metadata: object,
        currentText: object.originalText,
      );
    }

    state = state!.copyWith(
      textObjects: textObjects,
      textEdits: textEdits,
      ocrApplied: true,
      isDirty: true,
      fontNotice:
          'OCR text uses estimated fonts. Exact original fonts cannot be recovered from scans.',
    );
  }

  void clear() {
    state = null;
    _undoStack.clear();
    _redoStack.clear();
  }
}

final pdfEditorSessionProvider =
    StateNotifierProvider<PdfEditorSessionNotifier, PdfEditorSessionState?>(
  PdfEditorSessionNotifier.new,
);
