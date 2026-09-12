import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/tool_catalog.dart';
import '../../../shared/widgets/catalog_tool_icon.dart';

class ToolsHorizontalRow extends StatelessWidget {
  const ToolsHorizontalRow({
    super.key,
    required this.entries,
    required this.onTap,
    this.cardWidth = 112,
    this.iconSize = 72,
  });

  final List<ToolCatalogEntry> entries;
  final void Function(ToolCatalogEntry entry) onTap;
  final double cardWidth;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardWidth + 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return _HorizontalToolTile(
            entry: entry,
            width: cardWidth,
            iconSize: iconSize,
            onTap: () => onTap(entry),
          );
        },
      ),
    );
  }
}

class _HorizontalToolTile extends StatelessWidget {
  const _HorizontalToolTile({
    required this.entry,
    required this.width,
    required this.iconSize,
    required this.onTap,
  });

  final ToolCatalogEntry entry;
  final double width;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: entry.title,
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: width,
            decoration: BoxDecoration(
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CatalogToolIcon(entry: entry, size: iconSize),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  entry.title,
                  textAlign: TextAlign.center,
                  style: AppTypography.cardTitle(context).copyWith(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
