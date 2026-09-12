import 'package:flutter/material.dart';

import '../models/tool_catalog.dart';
import 'tool_icon_badge.dart';

/// Tool icon for catalog entries — vector badge (no PNG black-box artifacts).
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
    if (entry.tool != null) {
      return ToolIconBadge(tool: entry.tool!, dimension: size);
    }

    return ToolIconBadge(
      icon: entry.icon,
      accentColor: entry.color,
      dimension: size,
    );
  }
}
