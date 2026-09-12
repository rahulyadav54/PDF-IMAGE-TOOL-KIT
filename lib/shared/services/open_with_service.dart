import 'dart:async';

import 'package:flutter/services.dart';

class OpenWithFile {
  const OpenWithFile({
    required this.path,
    required this.fileName,
    this.mimeType = '',
  });

  final String path;
  final String fileName;
  final String mimeType;

  static OpenWithFile? fromMap(Object? value) {
    if (value is! Map) return null;

    final rawPath = value['path'];
    if (rawPath is! String || rawPath.isEmpty) return null;

    final rawName = value['fileName'];
    final rawMimeType = value['mimeType'];

    return OpenWithFile(
      path: rawPath,
      fileName: rawName is String && rawName.isNotEmpty ? rawName : rawPath,
      mimeType: rawMimeType is String ? rawMimeType : '',
    );
  }
}

class OpenWithService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.pdftoolbox/pdf_image_toolbox');
  static const EventChannel _eventChannel =
      EventChannel('com.pdftoolbox/pdf_image_toolbox/events');

  final StreamController<OpenWithFile> _controller =
      StreamController<OpenWithFile>.broadcast();
  StreamSubscription<dynamic>? _eventSubscription;
  OpenWithFile? _bufferedFile;
  bool _initialized = false;

  Stream<OpenWithFile> get stream => _controller.stream;

  Future<OpenWithFile?> initialize() async {
    if (_initialized) return takeBufferedFile();
    _initialized = true;

    try {
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        (event) {
          final file = OpenWithFile.fromMap(event);
          if (file != null) _emit(file);
        },
        onError: (_, __) {},
      );
    } catch (_) {}

    try {
      final payload = await _methodChannel.invokeMethod<Map<dynamic, dynamic>?>(
        'getPendingFile',
      );
      final file = OpenWithFile.fromMap(payload);
      if (file != null) _emit(file);
    } catch (_) {}

    return takeBufferedFile();
  }

  OpenWithFile? takeBufferedFile() {
    final file = _bufferedFile;
    _bufferedFile = null;
    return file;
  }

  void _emit(OpenWithFile file) {
    if (_controller.hasListener) {
      _controller.add(file);
    } else {
      _bufferedFile ??= file;
    }
  }

  void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _controller.close();
  }
}
