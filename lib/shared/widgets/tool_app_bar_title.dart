import 'package:flutter/material.dart';

import '../models/tool_type.dart';
import 'tool_illustration.dart';

/// App bar title with tool icon + name for quick visual recognition.
class ToolAppBarTitle extends StatelessWidget {
  const ToolAppBarTitle({
    super.key,
    required this.tool,
  });

  final ToolType tool;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ToolIllustration(tool: tool, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            tool.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
