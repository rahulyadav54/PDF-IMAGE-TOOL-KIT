import 'package:flutter/material.dart';

typedef PreferenceOption<T> = ({String label, String subtitle, T value});

Future<T?> showPreferencePicker<T>({
  required BuildContext context,
  required String title,
  required List<PreferenceOption<T>> options,
  required T selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          ...options.map(
            (option) => RadioListTile<T>(
              title: Text(option.label),
              subtitle: Text(option.subtitle),
              value: option.value,
              groupValue: selected,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
