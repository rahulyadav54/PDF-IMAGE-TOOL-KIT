import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/editor_models.dart';

class PdfEditorToolbar extends StatelessWidget {
  const PdfEditorToolbar({
    super.key,
    required this.activeTool,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onToolSelected,
  });

  final PdfEditorTool activeTool;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final ValueChanged<PdfEditorTool> onToolSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: canUndo ? onUndo : null,
                    icon: const Icon(Icons.undo_rounded),
                    tooltip: 'Undo',
                  ),
                  IconButton(
                    onPressed: canRedo ? onRedo : null,
                    icon: const Icon(Icons.redo_rounded),
                    tooltip: 'Redo',
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  _ToolChip(
                    icon: Icons.near_me_outlined,
                    label: 'Select',
                    selected: activeTool == PdfEditorTool.select,
                    onTap: () => onToolSelected(PdfEditorTool.select),
                  ),
                  _ToolChip(
                    icon: Icons.text_fields_rounded,
                    label: 'Text',
                    selected: activeTool == PdfEditorTool.text,
                    onTap: () => onToolSelected(PdfEditorTool.text),
                  ),
                  _ToolChip(
                    icon: Icons.add_rounded,
                    label: 'Add Text',
                    selected: activeTool == PdfEditorTool.addText,
                    onTap: () => onToolSelected(PdfEditorTool.addText),
                  ),
                  _ToolChip(
                    icon: Icons.image_outlined,
                    label: 'Image',
                    selected: activeTool == PdfEditorTool.image,
                    onTap: () => onToolSelected(PdfEditorTool.image),
                  ),
                  _ToolChip(
                    icon: Icons.draw_rounded,
                    label: 'Draw',
                    selected: activeTool == PdfEditorTool.draw,
                    onTap: () => onToolSelected(PdfEditorTool.draw),
                  ),
                  _ToolChip(
                    icon: Icons.highlight_rounded,
                    label: 'Highlight',
                    selected: activeTool == PdfEditorTool.highlight,
                    onTap: () => onToolSelected(PdfEditorTool.highlight),
                  ),
                  _ToolChip(
                    icon: Icons.format_underlined,
                    label: 'Underline',
                    selected: activeTool == PdfEditorTool.underline,
                    onTap: () => onToolSelected(PdfEditorTool.underline),
                  ),
                  _ToolChip(
                    icon: Icons.format_strikethrough,
                    label: 'Strike',
                    selected: activeTool == PdfEditorTool.strikethrough,
                    onTap: () => onToolSelected(PdfEditorTool.strikethrough),
                  ),
                  _ToolChip(
                    icon: Icons.draw_outlined,
                    label: 'Pen',
                    selected: activeTool == PdfEditorTool.pen,
                    onTap: () => onToolSelected(PdfEditorTool.pen),
                  ),
                  _ToolChip(
                    icon: Icons.auto_fix_off_outlined,
                    label: 'Eraser',
                    selected: activeTool == PdfEditorTool.eraser,
                    onTap: () => onToolSelected(PdfEditorTool.eraser),
                  ),
                  _ToolChip(
                    icon: Icons.rectangle_outlined,
                    label: 'Rect',
                    selected: activeTool == PdfEditorTool.rectangle,
                    onTap: () => onToolSelected(PdfEditorTool.rectangle),
                  ),
                  _ToolChip(
                    icon: Icons.circle_outlined,
                    label: 'Circle',
                    selected: activeTool == PdfEditorTool.circle,
                    onTap: () => onToolSelected(PdfEditorTool.circle),
                  ),
                  _ToolChip(
                    icon: Icons.arrow_right_alt_rounded,
                    label: 'Arrow',
                    selected: activeTool == PdfEditorTool.arrow,
                    onTap: () => onToolSelected(PdfEditorTool.arrow),
                  ),
                  _ToolChip(
                    icon: Icons.notes_rounded,
                    label: 'Text Box',
                    selected: activeTool == PdfEditorTool.textBox,
                    onTap: () => onToolSelected(PdfEditorTool.textBox),
                  ),
                  _ToolChip(
                    icon: Icons.sticky_note_2_outlined,
                    label: 'Note',
                    selected: activeTool == PdfEditorTool.stickyNote,
                    onTap: () => onToolSelected(PdfEditorTool.stickyNote),
                  ),
                  _ToolChip(
                    icon: Icons.draw_rounded,
                    label: 'Signature',
                    selected: activeTool == PdfEditorTool.signature,
                    onTap: () => onToolSelected(PdfEditorTool.signature),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.electricBlue.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.electricBlue : AppColors.borderLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? AppColors.electricBlue
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? AppColors.electricBlue
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
