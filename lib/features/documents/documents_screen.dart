import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../core/theme/app_spacing.dart';

import '../../core/theme/app_typography.dart';

import '../../core/utils/incoming_file_types.dart';

import '../../shared/models/recent_file.dart';

import '../../shared/providers/recent_files_provider.dart';
import '../../shared/services/starred_files_service.dart';

import '../../shared/widgets/app_empty_state.dart';

import '../../shared/widgets/app_search_field.dart';

import '../../shared/widgets/file_row.dart';



enum FileFilter { all, starred, pdfs, images, documents }



enum FileSort { newest, oldest, name }



class DocumentsScreen extends ConsumerStatefulWidget {

  const DocumentsScreen({super.key});



  @override

  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();

}



class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {

  String _query = '';

  FileFilter _filter = FileFilter.all;

  FileSort _sort = FileSort.newest;



  bool _matchesFilter(RecentFile file, Set<String> starred) {

    final kind = IncomingFileTypes.detect(path: file.filePath);

    switch (_filter) {

      case FileFilter.starred:
        return starred.contains(file.filePath);

      case FileFilter.pdfs:

        return kind == IncomingFileKind.pdf;

      case FileFilter.images:

        return kind == IncomingFileKind.image;

      case FileFilter.documents:

        return kind == IncomingFileKind.word || kind == IncomingFileKind.excel;

      case FileFilter.all:

        return true;

    }

  }



  @override

  Widget build(BuildContext context) {

    final state = ref.watch(recentFilesProvider);
    final starred = ref.watch(starredPathsProvider);



    return SafeArea(

      child: state.when(

        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),

        error: (_, __) => AppEmptyState(

          icon: Icons.folder_off_outlined,

          title: 'Could not load files',

          message: 'Something went wrong while loading your files.',

          actionLabel: 'Retry',

          onAction: () => ref.read(recentFilesProvider.notifier).refresh(),

        ),

        data: (recentState) {

          var files = recentState.files.where((file) {

            final name = file.fileName.toLowerCase();

            if (_query.isNotEmpty && !name.contains(_query.toLowerCase())) {

              return false;

            }

            return _matchesFilter(file, starred);

          }).toList();



          files = switch (_sort) {

            FileSort.newest => [...files],

            FileSort.oldest => files.reversed.toList(),

            FileSort.name => [...files]..sort((a, b) => a.fileName.compareTo(b.fileName)),

          };



          return RefreshIndicator(

            onRefresh: () => ref.read(recentFilesProvider.notifier).refresh(),

            child: CustomScrollView(

              slivers: [

                SliverToBoxAdapter(

                  child: Padding(

                    padding: const EdgeInsets.fromLTRB(

                      AppSpacing.screenH,

                      AppSpacing.sm,

                      AppSpacing.screenH,

                      AppSpacing.md,

                    ),

                    child: Text('My Files', style: AppTypography.screenTitle(context)),

                  ),

                ),

                SliverPadding(

                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),

                  sliver: SliverToBoxAdapter(

                    child: AppSearchField(

                      hintText: 'Search files',

                      onChanged: (v) => setState(() => _query = v),

                    ),

                  ),

                ),

                SliverToBoxAdapter(

                  child: Padding(

                    padding: const EdgeInsets.fromLTRB(

                      AppSpacing.screenH,

                      AppSpacing.md,

                      AppSpacing.screenH,

                      AppSpacing.sm,

                    ),

                    child: Row(

                      children: [

                        Expanded(

                          child: SingleChildScrollView(

                            scrollDirection: Axis.horizontal,

                            child: SegmentedButton<FileFilter>(

                              segments: const [

                                ButtonSegment(value: FileFilter.all, label: Text('All')),

                                ButtonSegment(value: FileFilter.starred, label: Text('Starred')),

                                ButtonSegment(value: FileFilter.pdfs, label: Text('PDFs')),

                                ButtonSegment(value: FileFilter.images, label: Text('Images')),

                                ButtonSegment(

                                  value: FileFilter.documents,

                                  label: Text('Documents'),

                                ),

                              ],

                              selected: {_filter},

                              onSelectionChanged: (s) => setState(() => _filter = s.first),

                            ),

                          ),

                        ),

                        const SizedBox(width: AppSpacing.sm),

                        PopupMenuButton<FileSort>(

                          icon: const Icon(Icons.sort, size: 22),

                          tooltip: 'Sort',

                          onSelected: (v) => setState(() => _sort = v),

                          itemBuilder: (context) => const [

                            PopupMenuItem(value: FileSort.newest, child: Text('Newest first')),

                            PopupMenuItem(value: FileSort.oldest, child: Text('Oldest first')),

                            PopupMenuItem(value: FileSort.name, child: Text('Name A–Z')),

                          ],

                        ),

                      ],

                    ),

                  ),

                ),

                if (files.isEmpty)

                  SliverFillRemaining(

                    hasScrollBody: false,

                    child: AppEmptyState(

                      icon: Icons.folder_open_outlined,

                      title: 'No files found',

                      message: _query.isNotEmpty

                          ? 'Try a different search term.'

                          : 'Processed files and imports from other apps will appear here.',

                    ),

                  )

                else

                  SliverList(

                    delegate: SliverChildBuilderDelegate(

                      (context, index) => FileRow(

                        file: files[index],

                        isAvailable: recentState.isAvailable(files[index]),

                        showDivider: index < files.length - 1,

                      ),

                      childCount: files.length,

                    ),

                  ),

                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

              ],

            ),

          );

        },

      ),

    );

  }

}

