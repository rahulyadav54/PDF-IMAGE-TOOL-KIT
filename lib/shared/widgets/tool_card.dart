import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../models/tool_catalog.dart';
import 'catalog_tool_icon.dart';

enum ToolCardVariant { compact, featured, pinned }

/// Reusable tool card — icon, title, description, optional in-card pin action.
class ToolCard extends StatefulWidget {
  const ToolCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.variant = ToolCardVariant.compact,
    this.isPinned = false,
    this.showPin = false,
    this.onPinToggle,
  });

  final ToolCatalogEntry entry;
  final VoidCallback onTap;
  final ToolCardVariant variant;
  final bool isPinned;
  final bool showPin;
  final VoidCallback? onPinToggle;

  @override
  State<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard> {
  bool _pressed = false;

  double get _iconSize {
    switch (widget.variant) {
      case ToolCardVariant.featured:
        return 44;
      case ToolCardVariant.pinned:
        return 36;
      case ToolCardVariant.compact:
        return 40;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = widget.variant == ToolCardVariant.pinned
        ? AppRadius.sm
        : AppRadius.md;

    return Semantics(
      button: true,
      label: widget.entry.title,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 100),
          child: Material(
            color: scheme.surfaceContainerLow,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: EdgeInsets.all(
                widget.variant == ToolCardVariant.pinned
                    ? AppSpacing.md
                    : AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CatalogToolIcon(entry: widget.entry, size: _iconSize),
                      const Spacer(),
                      if (widget.showPin && widget.onPinToggle != null)
                        _PinButton(
                          isPinned: widget.isPinned,
                          onPressed: widget.onPinToggle!,
                        ),
                    ],
                  ),
                  SizedBox(
                    height: widget.variant == ToolCardVariant.pinned
                        ? AppSpacing.sm
                        : AppSpacing.md,
                  ),
                  Text(
                    widget.entry.title,
                    style: AppTypography.cardTitle(context).copyWith(
                      fontSize: widget.variant == ToolCardVariant.pinned ? 13 : 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.variant != ToolCardVariant.pinned) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.entry.subtitle,
                      style: AppTypography.cardSubtitle(context),
                      maxLines: widget.variant == ToolCardVariant.compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinButton extends StatelessWidget {
  const _PinButton({required this.isPinned, required this.onPressed});

  final bool isPinned;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            size: 18,
            color: isPinned ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
