import 'dart:typed_data';

import 'package:image/image.dart' as img;

class PreparePdfPageParams {
  const PreparePdfPageParams({
    required this.bytes,
    required this.maxWidth,
    required this.jpegQuality,
  });

  final Uint8List bytes;
  final int maxWidth;
  final int jpegQuality;
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

PreparedPdfPageData preparePdfPageInIsolate(PreparePdfPageParams params) {
  final decoded = img.decodeImage(params.bytes);
  if (decoded == null) {
    throw const FormatException('Unable to decode image.');
  }

  final oriented = img.bakeOrientation(decoded);
  final resized = oriented.width > params.maxWidth
      ? img.copyResize(oriented, width: params.maxWidth)
      : oriented;

  return PreparedPdfPageData(
    bytes: Uint8List.fromList(
      img.encodeJpg(resized, quality: params.jpegQuality.clamp(70, 95)),
    ),
    width: resized.width,
    height: resized.height,
  );
}
