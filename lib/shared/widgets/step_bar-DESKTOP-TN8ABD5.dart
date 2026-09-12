import 'package:flutter/material.dart';

/// Horizontal progress indicator for multi-step tool flows.
class StepBar extends StatelessWidget {
  const StepBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 2,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final steps = totalSteps.clamp(1, 8);

    return Semantics(
      label: 'Step $currentStep of $steps',
      child: Row(
        children: List.generate(steps, (index) {
          final step = index + 1;
          final active = step <= currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < steps - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: active ? colors.primary : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
