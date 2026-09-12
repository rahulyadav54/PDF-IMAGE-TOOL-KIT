import 'package:flutter/material.dart';

import '../assets/tool_assets.dart';
import '../models/tool_type.dart';

/// Custom tool illustration with Material icon fallback.
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
    final assetPath = ToolAssets.pathFor(tool);

    return Semantics(
      label: semanticLabel ?? tool.title,
      image: true,
      child: assetPath == null
          ? Icon(tool.icon, size: size * 0.55, color: tool.accentColor)
          : Image.asset(
              assetPath,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                tool.icon,
                size: size * 0.55,
                color: tool.accentColor,
              ),
            ),
    );
  }
}
