import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.onChooseAnother,
    this.onGoBack,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onChooseAnother;
  final VoidCallback? onGoBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.resultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 48),
            Icon(Icons.error_outline, size: 48, color: colors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            if (onRetry != null)
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            if (onChooseAnother != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onChooseAnother,
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Choose another file'),
              ),
            ],
            if (onGoBack != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onGoBack,
                child: const Text('Go back'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
