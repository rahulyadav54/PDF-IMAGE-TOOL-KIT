import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../shared/services/document_processing/document_boundary_detector.dart';
import '../../../shared/services/document_processing/document_frame_analyzer.dart';
import '../../../shared/services/document_processing/document_image_pipeline.dart';

class GeometryIsolateParams {
  const GeometryIsolateParams({
    required this.bytes,
    required this.jpegQuality,
    this.cornerCoords,
    this.geometryPolicy = GeometryPolicy.autoDetect,
  });

  final Uint8List bytes;
  final int jpegQuality;
  final List<double>? cornerCoords;
  final GeometryPolicy geometryPolicy;
}

class GeometryIsolateResult {
  const GeometryIsolateResult({
    required this.bytes,
    required this.width,
    required this.height,
    required this.confidence,
    required this.appliedPerspective,
    required this.appliedContentTrim,
    required this.needsManualAdjustment,
    required this.cornerCoords,
    required this.rotationDegrees,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final double confidence;
  final bool appliedPerspective;
  final bool appliedContentTrim;
  final bool needsManualAdjustment;
  final List<double> cornerCoords;
  final int rotationDegrees;
}

GeometryIsolateResult processGeometryInIsolate(GeometryIsolateParams params) {
  final decoded = img.decodeImage(params.bytes);
  if (decoded == null) {
    throw const FormatException('Unable to decode captured image.');
  }

  List<DocumentCorner>? manualCorners;
  if (params.cornerCoords != null && params.cornerCoords!.length == 8) {
    manualCorners = [
      for (var i = 0; i < 8; i += 2)
        DocumentCorner(params.cornerCoords![i], params.cornerCoords![i + 1]),
    ];
  }

  final policy = manualCorners != null
      ? GeometryPolicy.manual
      : params.geometryPolicy;

  final pipeline = DocumentImagePipeline.process(
    decoded,
    enableDocumentGeometry: true,
    geometryPolicy: policy,
    manualCorners: manualCorners,
  );

  final encoded = DocumentImagePipeline.encodeJpeg(
    pipeline.image,
    params.jpegQuality,
  );

  final corners = pipeline.corners;
  final cornerCoords = corners.length == 4
      ? [
          corners[0].x,
          corners[0].y,
          corners[1].x,
          corners[1].y,
          corners[2].x,
          corners[2].y,
          corners[3].x,
          corners[3].y,
        ]
      : <double>[];

  return GeometryIsolateResult(
    bytes: encoded,
    width: pipeline.image.width,
    height: pipeline.image.height,
    confidence: pipeline.documentConfidence,
    appliedPerspective: pipeline.appliedPerspective,
    appliedContentTrim: pipeline.appliedContentTrim,
    needsManualAdjustment: pipeline.needsManualAdjustment,
    cornerCoords: cornerCoords,
    rotationDegrees: pipeline.rotationDegrees,
  );
}

List<DocumentCorner> cornersFromCoords(List<double> coords) {
  if (coords.length != 8) return [];
  return [
    for (var i = 0; i < 8; i += 2) DocumentCorner(coords[i], coords[i + 1]),
  ];
}
