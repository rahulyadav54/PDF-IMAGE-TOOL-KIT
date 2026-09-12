import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Loads a bundled asset when present; otherwise shows a matching Material icon.
class AssetIcon extends StatelessWidget {
  const AssetIcon({
    super.key,
    required this.assetPath,
    required this.fallbackIcon,
    this.size = 40,
    this.color,
    this.semanticLabel,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _assetExists(assetPath),
      builder: (context, snapshot) {
        final exists = snapshot.data ?? false;
        if (!exists) {
          return Semantics(
            label: semanticLabel,
            child: Icon(fallbackIcon, size: size, color: color),
          );
        }

        return Semantics(
          label: semanticLabel,
          image: true,
          child: Image.asset(
            assetPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              fallbackIcon,
              size: size,
              color: color,
            ),
          ),
        );
      },
    );
  }

  static Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }
}
