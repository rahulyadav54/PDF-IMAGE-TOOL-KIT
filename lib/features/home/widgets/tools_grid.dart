import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/tool_catalog.dart';
import '../../../shared/models/tool_type.dart';
import '../../../shared/widgets/tool_card.dart';

class ToolsGrid extends StatelessWidget {
  const ToolsGrid({
    super.key,
    required this.tools,
  });

  final List<ToolType> tools;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 600 ? 3 : 2;
        final aspectRatio = width >= 600 ? 0.92 : 0.82;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemCount: tools.length,
          itemBuilder: (context, index) {
            final tool = tools[index];
            return ToolCard(
              entry: ToolCatalog.fromTool(tool),
              onTap: () => context.push(tool.route),
            );
          },
        );
      },
    );
  }
}
