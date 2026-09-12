import 'package:flutter/material.dart';

enum SplitMode {
  extractRange(
    label: 'Extract Pages',
    description: 'Extract a specific page range into one PDF',
    icon: Icons.content_cut_outlined,
  ),
  splitEveryPage(
    label: 'Split Every Page',
    description: 'Create a separate PDF for each page',
    icon: Icons.layers_outlined,
  );

  const SplitMode({
    required this.label,
    required this.description,
    required this.icon,
  });

  final String label;
  final String description;
  final IconData icon;
}
