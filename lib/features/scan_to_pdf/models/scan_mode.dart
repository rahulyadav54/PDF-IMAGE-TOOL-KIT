import 'package:flutter/material.dart';

enum ScanMode {
  document(
    label: 'Document',
    description: 'Standard document scanning',
    icon: Icons.description_outlined,
    defaultEnhance: 'document',
  ),
  idCard(
    label: 'ID card',
    description: 'Front and back on one page',
    icon: Icons.badge_outlined,
    defaultEnhance: 'document',
  ),
  receipt(
    label: 'Receipt',
    description: 'High contrast narrow capture',
    icon: Icons.receipt_long_outlined,
    defaultEnhance: 'blackAndWhite',
  ),
  book(
    label: 'Book',
    description: 'Curved page enhancement',
    icon: Icons.menu_book_outlined,
    defaultEnhance: 'magicColor',
  );

  const ScanMode({
    required this.label,
    required this.description,
    required this.icon,
    required this.defaultEnhance,
  });

  final String label;
  final String description;
  final String defaultEnhance;
  final IconData icon;
}
