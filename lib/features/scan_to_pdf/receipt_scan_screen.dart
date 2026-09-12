import 'package:flutter/material.dart';

import 'models/scan_mode.dart';
import 'scan_to_pdf_screen.dart';

/// Receipt-optimized scanner using narrow-document enhancement presets.
class ReceiptScanScreen extends StatelessWidget {
  const ReceiptScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScanToPdfScreen(initialMode: ScanMode.receipt);
  }
}
