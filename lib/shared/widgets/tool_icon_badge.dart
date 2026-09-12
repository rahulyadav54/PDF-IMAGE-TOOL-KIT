import 'package:flutter/material.dart';

import '../models/tool_type.dart';

enum ToolIconSize { small, medium, large }

/// Colorful tool icon badge — easy to recognize without reading text.
class ToolIconBadge extends StatelessWidget {
  const ToolIconBadge({
    super.key,
    required this.tool,
    this.size = ToolIconSize.medium,
  });

  final ToolType tool;
  final ToolIconSize size;

  double get _boxSize {
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
    return Container(
      width: _boxSize,
      height: _boxSize,
      decoration: BoxDecoration(
        color: tool.accentColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(_boxSize * 0.28),
        border: Border.all(
          color: tool.accentColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Icon(
        tool.icon,
        color: tool.accentColor,
        size: _iconSize,
      ),
    );
  }
}
