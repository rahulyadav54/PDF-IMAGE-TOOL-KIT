import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/models/tool_catalog.dart';
import '../../shared/providers/pinned_tools_provider.dart';
import '../../shared/providers/recent_files_provider.dart';
import '../../shared/services/starred_files_service.dart';
import '../../shared/widgets/app_empty_state.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/banner_ad_widget.dart';
import '../../shared/widgets/file_row.dart';
import '../../shared/widgets/file_row_skeleton.dart';
import '../../shared/widgets/privacy_card.dart';
import '../../shared/widgets/pro_banner.dart';
import '../../shared/widgets/responsive_tool_grid.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/tool_card.dart';

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
    final scheme = Theme.of(context).colorScheme;

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
              sliver: const SliverToBoxAdapter(child: PrivacyCard()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sectionGap)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              sliver: const SliverToBoxAdapter(
                child: SectionHeader(title: 'Start with'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              sliver: SliverGrid(
                gridDelegate: ResponsiveToolGrid.sliverDelegate(
                  context,
                  featured: true,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = ToolCatalog.homeStartWith[index];
                    return ToolCard(
                      entry: entry,
                      variant: ToolCardVariant.featured,
                      onTap: () => context.push(entry.route),
                      showPin: true,
                      isPinned: pinnedRoutes.contains(entry.route),
                      onPinToggle: () => ref
                          .read(pinnedToolRoutesProvider.notifier)
                          .toggle(entry.route),
                    );
                  },
                  childCount: ToolCatalog.homeStartWith.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sectionGap)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: pinnedEntries.isEmpty ? 'Your tools' : 'Your tools',
                ),
              ),
            ),
            if (pinnedEntries.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                sliver: SliverToBoxAdapter(
                  child: Material(
                    color: scheme.surfaceContainerLow,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      side: BorderSide(color: scheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pin your favorite tools for quick access.',
                            style: AppTypography.cardSubtitle(context),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: () => context.go('/tools-hub'),
                            child: const Text('Browse tools'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 108,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                    itemCount: pinnedEntries.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final entry = pinnedEntries[index];
                      return SizedBox(
                        width: 132,
                        child: ToolCard(
                          entry: entry,
                          variant: ToolCardVariant.pinned,
                          onTap: () => context.push(entry.route),
                          showPin: true,
                          isPinned: true,
                          onPinToggle: () => ref
                              .read(pinnedToolRoutesProvider.notifier)
                              .toggle(entry.route),
                        ),
                      );
                    },
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sectionGap)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Workflows',
                  actionLabel: 'See all',
                  action: () => context.push('/workflows'),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              sliver: SliverToBoxAdapter(
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push('/workflows'),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          const Icon(Icons.account_tree_outlined),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'One-tap pipelines',
                                  style: AppTypography.cardTitle(context),
                                ),
                                Text(
                                  'Scan → Compress → Lock and more',
                                  style: AppTypography.cardSubtitle(context),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sectionGap)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              sliver: const SliverToBoxAdapter(
                child: SectionHeader(title: 'Quick actions'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              sliver: SliverGrid(
                gridDelegate: ResponsiveToolGrid.sliverDelegate(context),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = ToolCatalog.homeQuickActions[index];
                    return ToolCard(
                      entry: entry,
                      onTap: () => context.push(entry.route),
                      showPin: true,
                      isPinned: pinnedRoutes.contains(entry.route),
                      onPinToggle: () => ref
                          .read(pinnedToolRoutesProvider.notifier)
                          .toggle(entry.route),
                    );
                  },
                  childCount: ToolCatalog.homeQuickActions.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sectionGap)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: starred.isEmpty ? 'Recent files' : 'Starred & recent',
                  actionLabel: 'See all',
                  action: () => context.go('/files'),
                ),
              ),
            ),
            recentAsync.when(
              loading: () => const SliverToBoxAdapter(child: FileRowSkeleton()),
              error: (_, __) => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                sliver: SliverToBoxAdapter(
                  child: Material(
                    color: scheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      side: BorderSide(color: scheme.outlineVariant),
                    ),
                    child: const AppEmptyState(
                      icon: Icons.error_outline,
                      title: 'Could not load files',
                      message: 'Pull down to try again.',
                    ),
                  ),
                ),
              ),
              data: (state) {
                if (state.files.isEmpty) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                    sliver: SliverToBoxAdapter(
                      child: Material(
                        color: scheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          side: BorderSide(color: scheme.outlineVariant),
                        ),
                        child: AppEmptyState(
                          icon: Icons.description_outlined,
                          title: 'No recent files',
                          message: 'Files you create or open will appear here.',
                          actionLabel: 'Browse files',
                          onAction: () => context.go('/files'),
                        ),
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
              sliver: const SliverToBoxAdapter(child: ProBanner()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            const SliverToBoxAdapter(child: BannerAdWidget()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }
}
