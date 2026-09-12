import 'package:flutter/material.dart';

import '../models/tool_type.dart';

enum ToolIconSize { small, medium, large }

/// Colorful rounded tool icon — crisp vectors, no raster background artifacts.
class ToolIconBadge extends StatelessWidget {
  const ToolIconBadge({
    super.key,
    this.tool,
    this.icon,
    this.accentColor,
    this.dimension,
    this.size = ToolIconSize.medium,
  }) : assert(tool != null || (icon != null && accentColor != null));

  final ToolType? tool;
  final IconData? icon;
  final Color? accentColor;
  final double? dimension;
  final ToolIconSize size;

  IconData get _icon => tool?.icon ?? icon!;
  Color get _color => tool?.accentColor ?? accentColor!;

  double get _boxSize {
    if (dimension != null) return dimension!;
    switch (size) {
      case ToolIconSize.small:
        return 36;
      case ToolIconSize.medium:
        return 48;
      case ToolIconSize.large:
        return 64;
    }
  }

  double get _iconSize {
    if (dimension != null) return dimension! * 0.46;
    switch (size) {
      case ToolIconSize.small:
        return 20;
      case ToolIconSize.medium:
        return 26;
      case ToolIconSize.large:
        return 34;
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = (_boxSize * 0.28).clamp(8.0, 20.0);

    return Container(
      width: _boxSize,
      height: _boxSize,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: _color.withValues(alpha: 0.32),
          width: 1.1,
        ),
      ),
      child: Icon(
        _icon,
        color: _color,
        size: _iconSize,
      ),
    );
  }
}
