import 'package:flutter/material.dart';

import '../models/split_mode.dart';

class SplitModeSelector extends StatelessWidget {
  const SplitModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final SplitMode selected;
  final ValueChanged<SplitMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: SplitMode.values.map((mode) {
        final isSelected = mode == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            child: InkWell(
              onTap: () => onChanged(mode),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Radio<SplitMode>(
                      value: mode,
                      groupValue: selected,
                      onChanged: (value) {
                        if (value != null) onChanged(value);
                      },
                    ),
                    Icon(mode.icon, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode.label,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            mode.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
