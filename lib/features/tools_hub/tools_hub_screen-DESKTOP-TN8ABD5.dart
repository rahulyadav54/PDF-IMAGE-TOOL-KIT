import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/models/tool_catalog.dart';
import '../../shared/widgets/app_search_field.dart';
import '../../shared/widgets/catalog_tool_icon.dart';
import '../../shared/widgets/section_header.dart';
import 'widgets/tools_horizontal_row.dart';

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

  @override
  Widget build(BuildContext context) {
    final isSearching = _query.isNotEmpty;
    final searchResults =
        isSearching ? ToolCatalog.search(_query) : const <ToolCatalogEntry>[];
    final pdf = isSearching ? const <ToolCatalogEntry>[] : _filter(ToolCatalog.pdfTools);
    final image =
        isSearching ? const <ToolCatalogEntry>[] : _filter(ToolCatalog.imageTools);
    final other =
        isSearching ? const <ToolCatalogEntry>[] : _filter(ToolCatalog.otherTools);
    final hasResults = isSearching
        ? searchResults.isNotEmpty
        : pdf.isNotEmpty || image.isNotEmpty || other.isNotEmpty;

    return SafeArea(
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.sm,
                AppSpacing.screenH,
                AppSpacing.md,
              ),
              child: Text('Tools', style: AppTypography.screenTitle(context)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            sliver: SliverToBoxAdapter(
              child: AppSearchField(
                controller: _searchController,
                hintText: 'Search tools (e.g. edit, compress, scan)',
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
                        'No tools match "$_query"',
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = searchResults[index];
                    return _SearchToolTile(
                      entry: entry,
                      onTap: () => _openTool(entry),
                    );
                  },
                  childCount: searchResults.length,
                ),
              ),
            )
          else ...[
            if (pdf.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                sliver: SliverToBoxAdapter(child: SectionHeader(title: 'PDF')),
              ),
              SliverToBoxAdapter(
                child: ToolsHorizontalRow(
                  entries: pdf,
                  onTap: _openTool,
                ),
              ),
            ],
            if (image.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Image')),
              ),
              SliverToBoxAdapter(
                child: ToolsHorizontalRow(
                  entries: image,
                  onTap: _openTool,
                ),
              ),
            ],
            if (other.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                sliver: SliverToBoxAdapter(child: SectionHeader(title: 'More')),
              ),
              SliverToBoxAdapter(
                child: ToolsHorizontalRow(
                  entries: other,
                  onTap: _openTool,
                ),
              ),
            ],
          ],
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }
}

class _SearchToolTile extends StatelessWidget {
  const _SearchToolTile({
    required this.entry,
    required this.onTap,
  });

  final ToolCatalogEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: entry.title,
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CatalogToolIcon(entry: entry, size: 64),
                const SizedBox(height: 8),
                Text(
                  entry.title,
                  textAlign: TextAlign.center,
                  style: AppTypography.cardTitle(context).copyWith(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
