import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/recent_files_provider.dart';
import '../../../shared/widgets/empty_state_card.dart';
import '../../../shared/widgets/recent_file_tile.dart';

class RecentFilesSection extends ConsumerWidget {
  const RecentFilesSection({super.key});

  static const int _homePreviewLimit = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentFilesProvider);
    final colors = Theme.of(context).colorScheme;

    return recentAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: colors.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Unable to load recent files.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ),
              TextButton(
                onPressed: () => ref.read(recentFilesProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (state) {
        if (state.files.isEmpty) {
          return const EmptyStateCard(
            compact: true,
            icon: Icons.history,
            title: 'No recent files yet',
            message: 'Process a file to see it here.',
          );
        }

        final preview = state.files.take(_homePreviewLimit).toList();

        return Column(
          children: [
            if (state.unavailableCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${state.unavailableCount} recent file(s) are no longer available.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.error,
                      ),
                ),
              ),
            ...preview.map(
              (file) => RecentFileTile(
                file: file,
                isAvailable: state.isAvailable(file),
                compact: true,
              ),
            ),
          ],
        );
      },
    );
  }
}
