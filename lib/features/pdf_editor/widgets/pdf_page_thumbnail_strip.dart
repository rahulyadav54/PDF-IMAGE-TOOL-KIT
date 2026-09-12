import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/editor_models.dart';

class PdfPageThumbnailStrip extends StatelessWidget {
  const PdfPageThumbnailStrip({
    super.key,
    required this.pages,
    required this.selectedPageId,
    required this.onPageSelected,
    required this.onAddPage,
  });

  final List<PdfEditorPage> pages;
  final String? selectedPageId;
  final ValueChanged<String> onPageSelected;
  final VoidCallback onAddPage;

  @override
  Widget build(BuildContext context) {
    final activePages = pages.where((p) => !p.isDeleted).toList();
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              itemCount: activePages.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final page = activePages[index];
                final selected = page.id == selectedPageId;
                return GestureDetector(
                  onTap: () => onPageSelected(page.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 52,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.electricBlue.withValues(alpha: 0.12)
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppColors.electricBlue
                            : AppColors.borderLight,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 20,
                          color: selected
                              ? AppColors.electricBlue
                              : colors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? AppColors.electricBlue
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            onPressed: onAddPage,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add page',
            color: AppColors.electricBlue,
          ),
        ],
      ),
    );
  }
}
