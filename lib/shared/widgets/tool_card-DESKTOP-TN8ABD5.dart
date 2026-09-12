import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';
import '../models/tool_type.dart';
import 'tool_illustration.dart';

/// Minimal tool tile: custom icon illustration + tool name only.
class ToolCard extends StatelessWidget {
  const ToolCard({
    super.key,
    required this.tool,
    required this.onTap,
  });

  final ToolType tool;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconSize = (constraints.maxWidth * 0.82).clamp(68.0, 108.0);

        return Semantics(
          button: true,
          label: tool.title,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ToolIllustration(tool: tool, size: iconSize),
                    const SizedBox(height: 10),
                    Text(
                      tool.title,
                      textAlign: TextAlign.center,
                      style: AppTypography.toolTitle(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
