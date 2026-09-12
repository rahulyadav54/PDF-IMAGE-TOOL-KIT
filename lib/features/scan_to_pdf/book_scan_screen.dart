import 'package:flutter/material.dart';

import 'models/scan_mode.dart';
import 'scan_to_pdf_screen.dart';

/// Book page scanner with magic-color enhancement preset.
class BookScanScreen extends StatelessWidget {
  const BookScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScanToPdfScreen(initialMode: ScanMode.book);
  }
}
