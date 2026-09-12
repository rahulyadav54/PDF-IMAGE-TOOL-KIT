import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../shared/providers/recent_files_provider.dart';
import '../../shared/widgets/empty_state_card.dart';
import '../../shared/widgets/recent_file_tile.dart';

class RecentFilesScreen extends ConsumerWidget {
  const RecentFilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentFilesProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Files'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'clear') {
                await _confirmClear(context, ref);
              } else if (value == 'remove_unavailable') {
                await _removeUnavailable(context, ref);
              }
            },
            itemBuilder: (context) {
              final unavailable = recentAsync.valueOrNull?.unavailableCount ?? 0;
              return [
                if (unavailable > 0)
                  const PopupMenuItem(
                    value: 'remove_unavailable',
                    child: Text('Remove unavailable files'),
                  ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Text('Clear all history'),
                ),
              ];
            },
          ),
        ],
      ),
      body: recentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colors.error),
                const SizedBox(height: 12),
                const Text('Unable to load recent files.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.read(recentFilesProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (state) {
          if (state.files.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: EmptyStateCard(
                  icon: Icons.history,
                  title: 'No recent files yet',
                  message: 'Processed files will appear here for quick access.',
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(recentFilesProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '${state.files.length} of ${AppConstants.maxRecentFiles} stored locally',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                if (state.unavailableCount > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${state.unavailableCount} file(s) are no longer available on this device.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.error,
                        ),
                  ),
                ],
                const SizedBox(height: 16),
                ...state.files.map(
                  (file) => RecentFileTile(
                    file: file,
                    isAvailable: state.isAvailable(file),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _removeUnavailable(BuildContext context, WidgetRef ref) async {
    final removed = await ref.read(recentFilesProvider.notifier).removeUnavailable();
    if (!context.mounted) return;

    final message = removed == 0
        ? 'No unavailable files to remove.'
        : 'Removed $removed unavailable file(s).';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear recent files?'),
        content: const Text('This will remove all recent file history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(recentFilesProvider.notifier).clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recent files cleared')),
        );
      }
    }
  }
}
