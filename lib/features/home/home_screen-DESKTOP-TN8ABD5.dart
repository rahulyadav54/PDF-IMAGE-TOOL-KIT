import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/models/tool_catalog.dart';
import '../../shared/providers/pinned_tools_provider.dart';
import '../../shared/providers/recent_files_provider.dart';
import '../../shared/services/starred_files_service.dart';
import '../../shared/widgets/app_empty_state.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/compact_tool_card.dart';
import '../../shared/widgets/file_row.dart';
import '../../shared/widgets/privacy_card.dart';
import '../../shared/widgets/section_header.dart';
import '../tools_hub/widgets/tools_horizontal_row.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final recentAsync = ref.watch(recentFilesProvider);
    final pinnedRoutes = ref.watch(pinnedToolRoutesProvider);
    final pinnedEntries = ref.read(pinnedToolRoutesProvider.notifier).pinnedEntries();
    final starred = ref.watch(starredPathsProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.read(recentFilesProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppHeader(
                trailing: IconButton(
                  onPressed: () => context.go('/settings'),
                  icon: const Icon(Icons.settings_outlined, size: 24),
                  tooltip: 'Settings',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              sliver: SliverToBoxAdapter(child: const PrivacyCard()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sectionGap)),
            if (pinnedEntries.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(title: 'Pinned tools'),
                ),
              ),
              SliverToBoxAdapter(
                child: ToolsHorizontalRow(
                  entries: pinnedEntries,
                  onTap: (entry) => context.push(entry.route),
                  cardWidth: 100,
                  iconSize: 56,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sectionGap)),
            ],
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(title: 'Quick actions'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.35,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = ToolCatalog.quickActions[index];
                    final isPinned = pinnedRoutes.contains(entry.route);
                    return Stack(
                      children: [
                        CompactToolCard(
                          entry: entry,
                          onTap: () => context.push(entry.route),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: Icon(
                              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                              size: 18,
                            ),
                            tooltip: isPinned ? 'Unpin tool' : 'Pin tool',
                            onPressed: () => ref
                                .read(pinnedToolRoutesProvider.notifier)
                                .toggle(entry.route),
                          ),
                        ),
                      ],
                    );
                  },
                  childCount: ToolCatalog.quickActions.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sectionGap)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: starred.isEmpty ? 'Recent documents' : 'Starred & recent',
                  actionLabel: 'See all',
                  action: () => context.go('/files'),
                ),
              ),
            ),
            recentAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
              error: (_, __) => SliverToBoxAdapter(
                child: AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load files',
                  message: 'Pull down to try again.',
                ),
              ),
              data: (state) {
                if (state.files.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                      child: const AppEmptyState(
                        icon: Icons.description_outlined,
                        title: 'No recent documents',
                        message: 'Files you create or open will appear here.',
                      ),
                    ),
                  );
                }

                final starredFiles = state.files
                    .where((f) => starred.contains(f.filePath))
                    .take(2)
                    .toList();
                final recentFiles = state.files
                    .where((f) => !starred.contains(f.filePath))
                    .take(starredFiles.isEmpty ? 4 : 2)
                    .toList();
                final preview = [...starredFiles, ...recentFiles];

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => FileRow(
                      file: preview[index],
                      isAvailable: state.isAvailable(preview[index]),
                      showDivider: index < preview.length - 1,
                    ),
                    childCount: preview.length,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sectionGap)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(title: 'Image tools'),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                  itemCount: ToolCatalog.homeImageTools.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final entry = ToolCatalog.homeImageTools[index];
                    return HorizontalToolChip(
                      entry: entry,
                      onTap: () => context.push(entry.route),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }
}
