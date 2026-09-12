import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/resize_mode.dart';

class ResizeConfigPanel extends StatelessWidget {
  const ResizeConfigPanel({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.lockAspectRatio,
    required this.onLockAspectRatioChanged,
    required this.orientation,
    required this.onOrientationChanged,
    required this.widthController,
    required this.heightController,
    required this.onDimensionChanged,
    required this.percentage,
    required this.onPercentageChanged,
    required this.targetFileSizeKb,
    required this.onTargetFileSizeChanged,
    required this.originalWidth,
    required this.originalHeight,
    this.validationError,
    this.enabled = true,
  });

  final ResizeMode mode;
  final ValueChanged<ResizeMode> onModeChanged;
  final bool lockAspectRatio;
  final ValueChanged<bool> onLockAspectRatioChanged;
  final ImageOrientation orientation;
  final ValueChanged<ImageOrientation> onOrientationChanged;
  final TextEditingController widthController;
  final TextEditingController heightController;
  final VoidCallback onDimensionChanged;
  final int percentage;
  final ValueChanged<int> onPercentageChanged;
  final int targetFileSizeKb;
  final ValueChanged<int> onTargetFileSizeChanged;
  final int originalWidth;
  final int originalHeight;
  final String? validationError;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resize Mode',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                ...ResizeMode.values.map((value) {
                  return RadioListTile<ResizeMode>(
                    value: value,
                    groupValue: mode,
                    onChanged: enabled ? (v) => onModeChanged(v!) : null,
                    title: Text(value.label),
                    subtitle: Text(
                      value.description,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (mode == ResizeMode.dimensions) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dimensions',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Original: $originalWidth×$originalHeight px',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widthController,
                          enabled: enabled,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Width (px)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => onDimensionChanged(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: heightController,
                          enabled: enabled,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Height (px)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => onDimensionChanged(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Lock aspect ratio'),
                    value: lockAspectRatio,
                    onChanged: enabled ? onLockAspectRatioChanged : null,
                  ),
                  if (!lockAspectRatio) ...[
                    const SizedBox(height: 8),
                    SegmentedButton<ImageOrientation>(
                      segments: ImageOrientation.values
                          .map(
                            (o) => ButtonSegment(
                              value: o,
                              label: Text(o.label),
                            ),
                          )
                          .toList(),
                      selected: {orientation},
                      onSelectionChanged: enabled
                          ? (selection) => onOrientationChanged(selection.first)
                          : null,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ] else if (mode == ResizeMode.percentage) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scale',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        '$percentage%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                      ),
                    ],
                  ),
                  Slider(
                    value: percentage.toDouble(),
                    min: 10,
                    max: 200,
                    divisions: 19,
                    label: '$percentage%',
                    onChanged: enabled ? (v) => onPercentageChanged(v.round()) : null,
                  ),
                  Text(
                    'Output: ${(originalWidth * percentage / 100).round()}×${(originalHeight * percentage / 100).round()} px',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target File Size',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Approximate target size — actual output may vary slightly.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: targetFileSizeKb.toDouble(),
                          min: 50,
                          max: 5000,
                          divisions: 99,
                          label: '$targetFileSizeKb KB',
                          onChanged: enabled
                              ? (v) => onTargetFileSizeChanged(v.round())
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 88,
                        child: Text(
                          '$targetFileSizeKb KB',
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        if (validationError != null) ...[
          const SizedBox(height: 8),
          Text(
            validationError!,
            style: TextStyle(color: colors.error),
          ),
        ],
      ],
    );
  }
}
