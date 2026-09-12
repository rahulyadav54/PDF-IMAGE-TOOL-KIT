// ignore_for_file: avoid_print

import 'dart:io';

import 'package:image/image.dart';

/// Copies main app icon from source folder into project assets (no source edits).
void main() {
  const sourcePath = r'icon/app icon.jpeg';
  const brandingDir = 'assets/branding';
  const launcherPath = 'icon/app_icon.png';

  final source = File(sourcePath);
  if (!source.existsSync()) {
    print('Missing: $sourcePath');
    exit(1);
  }

  Directory(brandingDir).createSync(recursive: true);

  final bytes = source.readAsBytesSync();
  final decoded = decodeImage(bytes);
  if (decoded == null) {
    print('Could not decode app icon.');
    exit(1);
  }

  final square = copyResizeCropSquare(decoded, size: 1024);
  final brandingPng = encodePng(square);
  final splashLogo = copyResize(square, width: 512, height: 512);

  File('$brandingDir/app_icon.png').writeAsBytesSync(brandingPng);
  File('$brandingDir/splash_logo.png').writeAsBytesSync(encodePng(splashLogo));
  File(launcherPath).writeAsBytesSync(brandingPng);

  print('Copied app icon to assets/branding/ and icon/app_icon.png');
}

Image copyResizeCropSquare(Image source, {required int size}) {
  final side = source.width < source.height ? source.width : source.height;
  final x = (source.width - side) / 2;
  final y = (source.height - side) / 2;
  final cropped = copyCrop(
    source,
    x: x.round(),
    y: y.round(),
    width: side,
    height: side,
  );
  return copyResize(cropped, width: size, height: size);
}
