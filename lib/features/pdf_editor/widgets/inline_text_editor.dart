import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/editor_models.dart';

class InlineTextEditor extends StatelessWidget {
  const InlineTextEditor({
    super.key,
    required this.metadata,
    required this.currentText,
    required this.onChanged,
    required this.onDone,
    required this.onDelete,
    required this.overflowMode,
    required this.onOverflowModeChanged,
  });

  final PdfTextObjectMetadata metadata;
  final String currentText;
  final ValueChanged<String> onChanged;
  final VoidCallback onDone;
  final VoidCallback onDelete;
  final TextOverflowMode overflowMode;
  final ValueChanged<TextOverflowMode> onOverflowModeChanged;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: currentText);

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Edit text',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete text',
                ),
              ],
            ),
            if (metadata.fontNotice != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                metadata.fontNotice!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.orange,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              style: TextStyle(
                fontSize: metadata.fontSize.clamp(12, 28),
                fontWeight: metadata.fontStyle.contains(PdfFontStyle.bold)
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontStyle: metadata.fontStyle.contains(PdfFontStyle.italic)
                    ? FontStyle.italic
                    : FontStyle.normal,
                color: metadata.color,
              ),
              decoration: InputDecoration(
                hintText: 'Enter text',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText:
                    'Font: ${metadata.fontFamily} • ${metadata.fontSize.toStringAsFixed(1)}pt',
              ),
              onChanged: onChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'If text is longer',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<TextOverflowMode>(
              segments: const [
                ButtonSegment(
                  value: TextOverflowMode.keepSize,
                  label: Text('Keep size'),
                ),
                ButtonSegment(
                  value: TextOverflowMode.fitText,
                  label: Text('Fit text'),
                ),
                ButtonSegment(
                  value: TextOverflowMode.resizeText,
                  label: Text('Resize area'),
                ),
              ],
              selected: {overflowMode},
              onSelectionChanged: (value) =>
                  onOverflowModeChanged(value.first),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onDone,
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
