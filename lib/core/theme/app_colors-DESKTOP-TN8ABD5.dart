import 'package:flutter/material.dart';

/// Premium productivity palette for PDF & Image Toolbox.
abstract final class AppColors {
  static const deepNavy = Color(0xFF0B1F4D);
  static const electricBlue = Color(0xFF1769FF);
  static const cyan = Color(0xFF20C7E8);
  static const green = Color(0xFF16A34A);
  static const orange = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const purple = Color(0xFF6C3BFF);
  static const violet = Color(0xFF8B5CF6);
  static const pink = Color(0xFFDB2777);
  static const teal = Color(0xFF0D9488);

  static const backgroundLight = Color(0xFFF4F6FA);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF64748B);
  static const borderLight = Color(0xFFE2E8F0);

  static const backgroundDark = Color(0xFF0F172A);
  static const surfaceDark = Color(0xFF1E293B);
  static const textSecondaryDark = Color(0xFF94A3B8);

  static const pdfBorder = Color(0xFFBFDBFE);
  static const imageBorder = Color(0xFFBBF7D0);
  static const otherBorder = Color(0xFFDDD6FE);

  static Color iconContainerBg(Color accent, {bool dark = false}) =>
      accent.withValues(alpha: dark ? 0.18 : 0.1);
}
