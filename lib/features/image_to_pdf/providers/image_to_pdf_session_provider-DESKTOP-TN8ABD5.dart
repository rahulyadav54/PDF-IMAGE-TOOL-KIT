import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/image_pdf_item.dart';
import '../models/image_pdf_processing_options.dart';
import '../models/pdf_page_config.dart';

final imageToPdfSessionProvider =
    StateNotifierProvider.autoDispose<ImageToPdfSessionNotifier, ImageToPdfSessionState>(
  (ref) => ImageToPdfSessionNotifier(),
);

class ImageToPdfSessionState {
  const ImageToPdfSessionState({
    this.images = const [],
    this.config = const PdfPageConfig(),
    this.processingOptions = const ImagePdfProcessingOptions(),
  });

  final List<ImagePdfItem> images;
  final PdfPageConfig config;
  final ImagePdfProcessingOptions processingOptions;

  ImageToPdfSessionState copyWith({
    List<ImagePdfItem>? images,
    PdfPageConfig? config,
    ImagePdfProcessingOptions? processingOptions,
  }) {
    return ImageToPdfSessionState(
      images: images ?? this.images,
      config: config ?? this.config,
      processingOptions: processingOptions ?? this.processingOptions,
    );
  }
}

class ImageToPdfSessionNotifier extends StateNotifier<ImageToPdfSessionState> {
  ImageToPdfSessionNotifier() : super(const ImageToPdfSessionState());

  void addImages(List<ImagePdfItem> items) {
    final existing = state.images.map((e) => e.filePath).toSet();
    final newItems = items.where((i) => !existing.contains(i.filePath));
    state = state.copyWith(images: [...state.images, ...newItems]);
  }

  void updateThumbnails(Map<String, String> thumbnails) {
    if (thumbnails.isEmpty) return;
    state = state.copyWith(
      images: state.images
          .map(
            (item) => thumbnails.containsKey(item.filePath)
                ? item.copyWith(thumbnailPath: thumbnails[item.filePath])
                : item,
          )
          .toList(),
    );
  }

  void remove(String id) {
    state = state.copyWith(
      images: state.images.where((i) => i.id != id).toList(),
    );
  }

  void reorder(int oldIndex, int newIndex) {
    final images = [...state.images];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = images.removeAt(oldIndex);
    images.insert(newIndex, item);
    state = state.copyWith(images: images);
  }

  void updateConfig(PdfPageConfig config) {
    state = state.copyWith(config: config);
  }

  void updateProcessingOptions(ImagePdfProcessingOptions options) {
    state = state.copyWith(processingOptions: options);
  }

  void toggleEnhancementSelection(String id, bool selected) {
    state = state.copyWith(
      images: state.images
          .map(
            (item) => item.id == id
                ? item.copyWith(selectedForEnhancement: selected)
                : item,
          )
          .toList(),
    );
  }

  void clear() => state = const ImageToPdfSessionState();
}
