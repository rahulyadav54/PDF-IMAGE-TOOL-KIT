import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/models/tool_catalog.dart';
import '../../shared/widgets/app_search_field.dart';
import '../../shared/widgets/responsive_tool_grid.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/tool_card.dart';
import 'widgets/tool_list_tile.dart';

class ToolsHubScreen extends StatefulWidget {
  const ToolsHubScreen({super.key});

  @override
  State<ToolsHubScreen> createState() => _ToolsHubScreenState();
}

class _ToolsHubScreenState extends State<ToolsHubScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ToolCatalogEntry> _filter(List<ToolCatalogEntry> items) =>
      items.where((e) => e.matches(_query)).toList();

  void _onQueryChanged(String value) {
    setState(() => _query = value.trim());
  }

  void _openTool(ToolCatalogEntry entry) => context.push(entry.route);

  List<Widget> _categorySection(String title, List<ToolCatalogEntry> entries) {
    if (entries.isEmpty) return const [];

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        sliver: SliverToBoxAdapter(child: SectionHeader(title: title)),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final entry = entries[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < entries.length - 1 ? AppSpacing.sm : 0,
                ),
                child: ToolListTile(
                  entry: entry,
                  onTap: () => _openTool(entry),
                ),
              );
            },
            childCount: entries.length,
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _query.isNotEmpty;
    final searchResults =
        isSearching ? ToolCatalog.search(_query) : const <ToolCatalogEntry>[];
    final scan = isSearching ? const <ToolCatalogEntry>[] : _filter(ToolCatalog.scanTools);
    final pdf = isSearching
        ? const <ToolCatalogEntry>[]
        : _filter(
            ToolCatalog.pdfTools
                .where((e) => e.route != ToolCatalog.scanTools.first.route)
                .toList(),
          );
    final image =
        isSearching ? const <ToolCatalogEntry>[] : _filter(ToolCatalog.imageTools);
    final document =
        isSearching ? const <ToolCatalogEntry>[] : _filter(ToolCatalog.documentTools);
    final hasResults = isSearching
        ? searchResults.isNotEmpty
        : scan.isNotEmpty ||
            pdf.isNotEmpty ||
            image.isNotEmpty ||
            document.isNotEmpty;

    return SafeArea(
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.md,
                AppSpacing.screenH,
                AppSpacing.sm,
              ),
              child: Text('Tools', style: AppTypography.screenTitle(context)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            sliver: SliverToBoxAdapter(
              child: AppSearchField(
                controller: _searchController,
                hintText: 'Search tools...',
                onChanged: _onQueryChanged,
              ),
            ),
          ),
          if (isSearching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  AppSpacing.md,
                  AppSpacing.screenH,
                  AppSpacing.sm,
                ),
                child: Text(
                  '${searchResults.length} result${searchResults.length == 1 ? '' : 's'}',
                  style: AppTypography.caption(context),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          if (!hasResults)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_outlined,
                        size: 40,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        isSearching
                            ? 'No tools match "$_query"'
                            : 'No tools available',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption(context),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (isSearching)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              sliver: SliverGrid(
                gridDelegate: ResponsiveToolGrid.sliverDelegate(context),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = searchResults[index];
                    return ToolCard(
                      entry: entry,
                      onTap: () => _openTool(entry),
                    );
                  },
                  childCount: searchResults.length,
                ),
              ),
            )
          else ...[
            ..._categorySection('Scan', scan),
            ..._categorySection('PDF', pdf),
            ..._categorySection('Image', image),
            ..._categorySection('Document', document),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }
}
