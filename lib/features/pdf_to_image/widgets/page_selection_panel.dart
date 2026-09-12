import 'package:flutter/material.dart';

import '../../split_pdf/widgets/page_range_input.dart';
import '../models/image_export_format.dart';

class PageSelectionPanel extends StatelessWidget {
  const PageSelectionPanel({
    super.key,
    required this.totalPages,
    required this.mode,
    required this.onModeChanged,
    required this.startController,
    required this.endController,
    this.rangeError,
  });

  final int totalPages;
  final PageSelectionMode mode;
  final ValueChanged<PageSelectionMode> onModeChanged;
  final TextEditingController startController;
  final TextEditingController endController;
  final String? rangeError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pages to Export',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ...PageSelectionMode.values.map((selectionMode) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: InkWell(
                onTap: () => onModeChanged(selectionMode),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Radio<PageSelectionMode>(
                        value: selectionMode,
                        groupValue: mode,
                        onChanged: (value) {
                          if (value != null) onModeChanged(value);
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectionMode.label,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              selectionMode.description,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        if (mode == PageSelectionMode.pageRange) ...[
          const SizedBox(height: 4),
          PageRangeInput(
            totalPages: totalPages,
            startController: startController,
            endController: endController,
            errorText: rangeError,
          ),
        ] else ...[
          const SizedBox(height: 4),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'All $totalPages pages will be exported as ${totalPages > 1 ? 'a ZIP archive' : 'a single image'}.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
