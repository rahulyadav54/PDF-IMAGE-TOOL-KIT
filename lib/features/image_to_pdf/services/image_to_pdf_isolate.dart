import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../shared/services/document_processing/document_image_pipeline.dart';

class PreparePdfPageParams {
  const PreparePdfPageParams({
    required this.bytes,
    required this.maxWidth,
    required this.jpegQuality,
    this.skipDocumentGeometry = false,
  });

  final Uint8List bytes;
  final int maxWidth;
  final int jpegQuality;
  final bool skipDocumentGeometry;
}

class PreparedPdfPageData {
  const PreparedPdfPageData({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

PreparedPdfPageData loadPreparedJpegPage(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Unable to decode image.');
  }

  final oriented = img.bakeOrientation(decoded);
  final encoded = DocumentImagePipeline.encodeJpeg(oriented, 88);

  return PreparedPdfPageData(
    bytes: encoded,
    width: oriented.width,
    height: oriented.height,
  );
}

PreparedPdfPageData preparePdfPageInIsolate(PreparePdfPageParams params) {
  final decoded = img.decodeImage(params.bytes);
  if (decoded == null) {
    throw const FormatException('Unable to decode image.');
  }

  final pipeline = DocumentImagePipeline.process(
    decoded,
    enableDocumentGeometry: !params.skipDocumentGeometry,
  );

  final resized = DocumentImagePipeline.resizeForOutput(
    pipeline.image,
    params.maxWidth,
  );

  return PreparedPdfPageData(
    bytes: DocumentImagePipeline.encodeJpeg(resized, params.jpegQuality),
    width: resized.width,
    height: resized.height,
  );
}
