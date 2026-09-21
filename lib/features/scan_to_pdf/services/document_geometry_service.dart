import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/document_processing/document_boundary_detector.dart';
import '../../../shared/services/document_processing/document_frame_analyzer.dart';
import '../../../shared/services/temp_file_service.dart';
import '../models/scan_capture_source.dart';
import 'document_geometry_isolate.dart';

final documentGeometryServiceProvider =
    Provider<DocumentGeometryService>((ref) => DocumentGeometryService(ref));

class DocumentGeometryFileResult {
  const DocumentGeometryFileResult({
    required this.geometryPath,
    required this.confidence,
    required this.appliedPerspective,
    required this.appliedContentTrim,
    required this.needsManualAdjustment,
    required this.corners,
    required this.rotationDegrees,
  });

  final String geometryPath;
  final double confidence;
  final bool appliedPerspective;
  final bool appliedContentTrim;
  final bool needsManualAdjustment;
  final List<DocumentCorner> corners;
  final int rotationDegrees;

  bool get geometryApplied => appliedPerspective || appliedContentTrim;
}

class DocumentGeometryService {
  DocumentGeometryService(this._ref);

  final Ref _ref;

  Future<DocumentGeometryFileResult> processCapture(
    String rawCapturePath, {
    List<DocumentCorner>? manualCorners,
    ScanCaptureSource source = ScanCaptureSource.gallery,
    int jpegQuality = 92,
  }) async {
    final bytes = await File(rawCapturePath).readAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('Captured image is empty.');
    }

    final cornerCoords = manualCorners != null && manualCorners.length == 4
        ? [
            manualCorners[0].x,
            manualCorners[0].y,
            manualCorners[1].x,
            manualCorners[1].y,
            manualCorners[2].x,
            manualCorners[2].y,
            manualCorners[3].x,
            manualCorners[3].y,
          ]
        : null;

    final geometryPolicy = manualCorners != null
        ? GeometryPolicy.manual
        : _policyForSource(source);

    final result = await compute(
      processGeometryInIsolate,
      GeometryIsolateParams(
        bytes: bytes,
        jpegQuality: jpegQuality,
        cornerCoords: cornerCoords,
        geometryPolicy: geometryPolicy,
      ),
    );

    final tempService = _ref.read(tempFileServiceProvider);
    final outputPath = await tempService.createTempFile(extension: '.jpg');
    await File(outputPath).writeAsBytes(result.bytes, flush: true);

    return DocumentGeometryFileResult(
      geometryPath: outputPath,
      confidence: result.confidence,
      appliedPerspective: result.appliedPerspective,
      appliedContentTrim: result.appliedContentTrim,
      needsManualAdjustment: result.needsManualAdjustment,
      corners: cornersFromCoords(result.cornerCoords),
      rotationDegrees: result.rotationDegrees,
    );
  }

  GeometryPolicy _policyForSource(ScanCaptureSource source) {
    switch (source) {
      case ScanCaptureSource.nativeScanner:
        return GeometryPolicy.preCropped;
      case ScanCaptureSource.gallery:
      case ScanCaptureSource.files:
        return GeometryPolicy.autoDetect;
    }
  }
}
