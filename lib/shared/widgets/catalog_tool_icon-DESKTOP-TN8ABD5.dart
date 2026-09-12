import 'package:flutter/material.dart';

import '../assets/tool_assets.dart';
import '../models/tool_catalog.dart';

/// Custom tool icon from assets with Material icon fallback.
class CatalogToolIcon extends StatelessWidget {
  const CatalogToolIcon({
    super.key,
    required this.entry,
    this.size = 56,
  });

  final ToolCatalogEntry entry;
  final double size;

  @override
  Widget build(BuildContext context) {
    final assetPath = ToolAssets.pathForEntry(entry);

    if (assetPath == null) {
      return Icon(entry.icon, size: size * 0.55, color: entry.color);
    }

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        entry.icon,
        size: size * 0.55,
        color: entry.color,
      ),
    );
  }
}
