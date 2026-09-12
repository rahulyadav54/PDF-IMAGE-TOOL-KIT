import 'package:flutter/material.dart';

import '../models/tool_type.dart';
import 'tool_icon_badge.dart';

/// Tool icon for [ToolType] screens and cards.
class ToolIllustration extends StatelessWidget {
  const ToolIllustration({
    super.key,
    required this.tool,
    this.size = 88,
    this.semanticLabel,
  });

  final ToolType tool;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? tool.title,
      child: ToolIconBadge(tool: tool, dimension: size),
    );
  }
}
