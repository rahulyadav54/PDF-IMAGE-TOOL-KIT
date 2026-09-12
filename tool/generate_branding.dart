// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

/// Generates launcher and splash PNG assets for Play Store branding.
void main() {
  final outDir = Directory('assets/branding');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  final iconDir = Directory('icon');
  if (!iconDir.existsSync()) iconDir.createSync(recursive: true);

  final icon = _createAppIcon(1024);
  File('assets/branding/app_icon.png').writeAsBytesSync(encodePng(icon));
  // Keep icon/icon.png as the launcher source — do not overwrite a custom icon.

  final foreground = _createForeground(1024);
  File('assets/branding/app_icon_foreground.png')
      .writeAsBytesSync(encodePng(foreground));

  final splashLogo = _createSplashLogo(480);
  File('assets/branding/splash_logo.png')
      .writeAsBytesSync(encodePng(splashLogo));

  final splashBackground = _createSplashBackground(1080, 1920);
  File('assets/branding/splash_background.png')
      .writeAsBytesSync(encodePng(splashBackground));

  final storeDir = Directory('store_assets/graphics');
  if (!storeDir.existsSync()) storeDir.createSync(recursive: true);

  final playStoreIcon = copyResize(icon, width: 512, height: 512);
  File('store_assets/graphics/play_store_icon_512.png')
      .writeAsBytesSync(encodePng(playStoreIcon));

  final featureGraphic = _createFeatureGraphic(1024, 500);
  File('store_assets/graphics/feature_graphic_1024x500.png')
      .writeAsBytesSync(encodePng(featureGraphic));

  print('Generated branding assets in assets/branding/');
  print('Generated store graphics in store_assets/graphics/');
}

Image _createSplashBackground(int width, int height) {
  final image = Image(width: width, height: height);

  for (var y = 0; y < height; y++) {
    final blend = (y / height * 0.85 + 0.05).clamp(0.0, 1.0);
    final r = _lerpChannel((_darkNavy >> 16) & 0xFF, (_brandBlue >> 16) & 0xFF, blend);
    final g = _lerpChannel((_darkNavy >> 8) & 0xFF, (_brandBlue >> 8) & 0xFF, blend);
    final b = _lerpChannel(_darkNavy & 0xFF, _brandBlue & 0xFF, blend);
    for (var x = 0; x < width; x++) {
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  _fillCircle(image, (width * 0.82).round(), (height * 0.14).round(), (width * 0.28).round(), _glowBlue);
  _fillCircle(image, (width * 0.12).round(), (height * 0.72).round(), (width * 0.22).round(), _glowBlue);
  _fillCircle(image, (width * 0.5).round(), (height * 0.42).round(), (width * 0.55).round(), _glowCenter);

  return image;
}

int _lerpChannel(int from, int to, double t) =>
    (from + (to - from) * t.clamp(0.0, 1.0)).round();

Image _createFeatureGraphic(int width, int height) {
  final image = Image(width: width, height: height);
  _fillRect(image, 0, 0, width, height, _brandBlue);

  final logoSize = (height * 0.55).round();
  final logo = _createForeground(logoSize);
  final logoX = (width * 0.08).round();
  final logoY = ((height - logoSize) / 2).round();
  compositeImage(image, logo, dstX: logoX, dstY: logoY);

  final textX = logoX + logoSize + (width * 0.04).round();
  final titleY = (height * 0.36).round();
  _drawTextBlock(
    image,
    textX,
    titleY,
    'DocForge',
    _white,
    (height * 0.11).round(),
  );
  _drawTextBlock(
    image,
    textX,
    titleY + (height * 0.16).round(),
    'Compress  Merge  Convert  Scan',
    _lightBlue,
    (height * 0.055).round(),
  );
  _drawTextBlock(
    image,
    textX,
    titleY + (height * 0.28).round(),
    'Offline. Private. On your device.',
    _white,
    (height * 0.05).round(),
  );

  return image;
}

void _drawTextBlock(
  Image image,
  int x,
  int y,
  String text,
  int color,
  int barHeight,
) {
  final barWidth = (text.length * barHeight * 0.55).round();
  _fillRoundedRect(image, x, y, x + barWidth, y + barHeight, barHeight * 0.3, color);
}

const _brandBlue = 0xFF1B6EF3;
const _darkNavy = 0xFF0D1B2A;
const _white = 0xFFFFFFFF;
const _lightBlue = 0xFF4A90F7;
const _glowBlue = 0x221B6EF3;
const _glowCenter = 0x141B6EF3;

Image _createAppIcon(int size) {
  final image = Image(width: size, height: size);
  final radius = size * 0.22;
  _fillRoundedRect(image, 0, 0, size, size, radius, _brandBlue);
  _drawForeground(image, size);
  return image;
}

Image _createForeground(int size) {
  final image = Image(width: size, height: size);
  _drawForeground(image, size);
  return image;
}

Image _createSplashLogo(int size) {
  final image = Image(width: size, height: size);
  final pad = (size * 0.08).round();
  _fillRoundedRect(
    image,
    pad,
    pad,
    size - pad,
    size - pad,
    size * 0.18,
    _brandBlue,
  );
  _drawForeground(image, size);
  return image;
}

void _drawForeground(Image image, int size) {
  final cx = size / 2;
  final cy = size / 2;
  final docW = size * 0.34;
  final docH = size * 0.42;

  _fillRoundedRect(
    image,
    (cx - docW * 0.55).round(),
    (cy - docH * 0.55).round(),
    (cx - docW * 0.55 + docW * 0.88).round(),
    (cy - docH * 0.55 + docH).round(),
    size * 0.04,
    _lightBlue,
  );

  _fillRoundedRect(
    image,
    (cx - docW * 0.35).round(),
    (cy - docH * 0.45).round(),
    (cx - docW * 0.35 + docW).round(),
    (cy - docH * 0.45 + docH).round(),
    size * 0.045,
    _white,
  );

  final lineLeft = (cx - docW * 0.2).round();
  final lineRight = (cx + docW * 0.35).round();
  for (var i = 0; i < 3; i++) {
    final y = (cy - docH * 0.15 + i * size * 0.06).round();
    _fillRect(image, lineLeft, y, lineRight, y + (size * 0.025).round(), _brandBlue);
  }

  final badgeSize = size * 0.14;
  _fillRoundedRect(
    image,
    (cx + docW * 0.05).round(),
    (cy + docH * 0.05).round(),
    (cx + docW * 0.05 + badgeSize).round(),
    (cy + docH * 0.05 + badgeSize).round(),
    size * 0.02,
    _brandBlue,
  );
  _fillCircle(
    image,
    (cx + docW * 0.05 + badgeSize * 0.35).round(),
    (cy + docH * 0.05 + badgeSize * 0.38).round(),
    (badgeSize * 0.12).round(),
    _white,
  );
  _fillRoundedRect(
    image,
    (cx + docW * 0.05 + badgeSize * 0.18).round(),
    (cy + docH * 0.05 + badgeSize * 0.55).round(),
    (cx + docW * 0.05 + badgeSize * 0.82).round(),
    (cy + docH * 0.05 + badgeSize * 0.78).round(),
    size * 0.01,
    _white,
  );
}

void _fillRoundedRect(
  Image image,
  int x1,
  int y1,
  int x2,
  int y2,
  double radius,
  int color,
) {
  for (var y = y1; y < y2; y++) {
    for (var x = x1; x < x2; x++) {
      if (_insideRoundedRect(x, y, x1, y1, x2, y2, radius)) {
        image.setPixelRgba(x, y, _r(color), _g(color), _b(color), _a(color));
      }
    }
  }
}

bool _insideRoundedRect(
  int x,
  int y,
  int x1,
  int y1,
  int x2,
  int y2,
  double radius,
) {
  final r = radius;
  final corners = [
    (x1 + r, y1 + r),
    (x2 - r, y1 + r),
    (x1 + r, y2 - r),
    (x2 - r, y2 - r),
  ];

  final inRect = x >= x1 && x < x2 && y >= y1 && y < y2;
  if (!inRect) return false;

  if (x < x1 + r && y < y1 + r) {
    return _dist(x, y, corners[0].$1, corners[0].$2) <= r;
  }
  if (x >= x2 - r && y < y1 + r) {
    return _dist(x, y, corners[1].$1, corners[1].$2) <= r;
  }
  if (x < x1 + r && y >= y2 - r) {
    return _dist(x, y, corners[2].$1, corners[2].$2) <= r;
  }
  if (x >= x2 - r && y >= y2 - r) {
    return _dist(x, y, corners[3].$1, corners[3].$2) <= r;
  }
  return true;
}

void _fillRect(Image image, int x1, int y1, int x2, int y2, int color) {
  fillRect(
    image,
    x1: x1,
    y1: y1,
    x2: x2,
    y2: y2,
    color: ColorRgba8(_r(color), _g(color), _b(color), _a(color)),
  );
}

void _fillCircle(Image image, int cx, int cy, int radius, int color) {
  final x1 = math.max(0, cx - radius);
  final y1 = math.max(0, cy - radius);
  final x2 = math.min(image.width - 1, cx + radius);
  final y2 = math.min(image.height - 1, cy + radius);

  for (var y = y1; y <= y2; y++) {
    for (var x = x1; x <= x2; x++) {
      if (_dist(x, y, cx, cy) <= radius) {
        image.setPixelRgba(x, y, _r(color), _g(color), _b(color), _a(color));
      }
    }
  }
}

double _dist(num x1, num y1, num x2, num y2) =>
    math.sqrt(math.pow(x1 - x2, 2) + math.pow(y1 - y2, 2));

int _r(int color) => (color >> 16) & 0xFF;
int _g(int color) => (color >> 8) & 0xFF;
int _b(int color) => color & 0xFF;
int _a(int color) => color > 0xFFFFFF ? (color >> 24) & 0xFF : 255;
