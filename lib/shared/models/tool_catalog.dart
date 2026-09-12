import 'package:flutter/material.dart';

import 'tool_type.dart';

enum ToolCatalogGroup { pdf, image, other }

class ToolCatalogEntry {
  const ToolCatalogEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    required this.group,
    this.tool,
    this.keywords = const [],
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final ToolCatalogGroup group;
  final ToolType? tool;
  final List<String> keywords;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;

    final haystack = [
      title,
      subtitle,
      route,
      ...keywords,
    ].join(' ').toLowerCase();

    final terms = q.split(RegExp(r'\s+'));
    return terms.every((term) => haystack.contains(term));
  }
}

abstract final class ToolCatalog {
  static ToolCatalogEntry fromTool(ToolType tool) => ToolCatalogEntry(
        title: tool.title,
        subtitle: tool.subtitle,
        icon: tool.icon,
        color: tool.accentColor,
        route: tool.route,
        group: _groupFor(tool),
        tool: tool,
        keywords: [tool.id, tool.title],
      );

  static ToolCatalogGroup _groupFor(ToolType tool) {
    switch (tool.category) {
      case ToolCategory.pdf:
        return ToolCatalogGroup.pdf;
      case ToolCategory.image:
        return ToolCatalogGroup.image;
      case ToolCategory.other:
      case ToolCategory.batch:
        return ToolCatalogGroup.other;
    }
  }

  static final List<ToolCatalogEntry> pdfTools = [
    fromTool(ToolType.scanToPdf),
    fromTool(ToolType.editPdf),
    fromTool(ToolType.compressPdf),
    fromTool(ToolType.mergePdf),
    fromTool(ToolType.splitPdf),
    ToolCatalogEntry(
      title: 'Extract Pages',
      subtitle: 'Pull specific pages from a PDF',
      icon: Icons.content_cut_outlined,
      color: ToolType.splitPdf.accentColor,
      route: ToolType.splitPdf.route,
      group: ToolCatalogGroup.pdf,
      tool: ToolType.splitPdf,
      keywords: ['extract', 'split', 'pages'],
    ),
    fromTool(ToolType.pdfToImage),
    ToolCatalogEntry(
      title: 'Rotate & Reorder',
      subtitle: 'Fix page order and orientation',
      icon: Icons.rotate_right_outlined,
      color: ToolType.pdfPageEditor.accentColor,
      route: ToolType.pdfPageEditor.route,
      group: ToolCatalogGroup.pdf,
      tool: ToolType.pdfPageEditor,
      keywords: ['rotate', 'reorder', 'orientation', 'sort', 'pages'],
    ),
    fromTool(ToolType.protectPdf),
  ];

  static final List<ToolCatalogEntry> imageTools = [
    fromTool(ToolType.imageToPdf),
    fromTool(ToolType.imageCompress),
    fromTool(ToolType.imageResize),
    fromTool(ToolType.imageConvert),
    fromTool(ToolType.imageStitch),
    fromTool(ToolType.idPhoto),
    fromTool(ToolType.imageWatermark),
    fromTool(ToolType.imageFilters),
  ];

  static final List<ToolCatalogEntry> otherTools = [
    fromTool(ToolType.batchProcessor),
  ];

  static List<ToolCatalogEntry> get all => [
        ...pdfTools,
        ...imageTools,
        ...otherTools,
      ];

  /// Unique searchable catalog (deduped by route + title).
  static List<ToolCatalogEntry> get searchable {
    final seen = <String>{};
    final entries = <ToolCatalogEntry>[];
    for (final entry in all) {
      final key = '${entry.route}|${entry.title}';
      if (seen.add(key)) entries.add(entry);
    }
    return entries;
  }

  static List<ToolCatalogEntry> search(String query) {
    final q = query.trim();
    if (q.isEmpty) return searchable;
    return searchable.where((entry) => entry.matches(q)).toList();
  }

  static List<ToolCatalogEntry> quickActions = [
    fromTool(ToolType.scanToPdf),
    fromTool(ToolType.editPdf),
    fromTool(ToolType.compressPdf),
    fromTool(ToolType.mergePdf),
    fromTool(ToolType.splitPdf),
  ];

  static List<ToolCatalogEntry> homeImageTools = [
    fromTool(ToolType.imageToPdf),
    fromTool(ToolType.imageCompress),
    fromTool(ToolType.imageWatermark),
    fromTool(ToolType.imageFilters),
  ];
}
