import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum ScanProcessingStage {
  detecting('Detecting document', Icons.document_scanner_outlined),
  cropping('Correcting perspective', Icons.crop_rotate),
  enhancing('Enhancing scan', Icons.auto_fix_high_outlined),
  finishing('Almost done', Icons.check_circle_outline);

  const ScanProcessingStage(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// CamScanner-style full-screen scan processing with smooth animations.
class ScanProcessingOverlay extends StatefulWidget {
  const ScanProcessingOverlay({
    super.key,
    required this.stage,
    required this.progress,
    this.previewPath,
    this.pageIndex = 1,
    this.pageTotal = 1,
    this.onCancel,
  });

  final ScanProcessingStage stage;
  final double progress;
  final String? previewPath;
  final int pageIndex;
  final int pageTotal;
  final VoidCallback? onCancel;

  @override
  State<ScanProcessingOverlay> createState() => _ScanProcessingOverlayState();
}

class _ScanProcessingOverlayState extends State<ScanProcessingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scanLineAnimation = CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = widget.progress.clamp(0.0, 1.0);

    return Material(
      color: Colors.black.withValues(alpha: 0.88),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Scanning',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  if (widget.pageTotal > 1)
                    Text(
                      'Page ${widget.pageIndex} / ${widget.pageTotal}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (widget.previewPath != null &&
                              File(widget.previewPath!).existsSync())
                            Image.file(
                              File(widget.previewPath!),
                              fit: BoxFit.cover,
                            )
                          else
                            Container(
                              color: scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.15),
                              child: Icon(
                                Icons.description_outlined,
                                size: 72,
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                          AnimatedBuilder(
                            animation: _scanLineAnimation,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _ScanLinePainter(
                                  progress: _scanLineAnimation.value,
                                ),
                              );
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.electricBlue
                                    .withValues(alpha: 0.85),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Row(
                  key: ValueKey(widget.stage),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.stage.icon, color: AppColors.electricBlue),
                    const SizedBox(width: 10),
                    Text(
                      widget.stage.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TweenAnimationBuilder<double>(
                tween: Tween(end: progress),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          color: AppColors.electricBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(value * 100).round()}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              if (widget.onCancel != null)
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  const _ScanLinePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.electricBlue.withValues(alpha: 0.0),
          AppColors.electricBlue.withValues(alpha: 0.55),
          AppColors.electricBlue.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, y - 24, size.width, 48));

    canvas.drawRect(Rect.fromLTWH(0, y - 1, size.width, 2), paint);

    final glow = Paint()
      ..color = AppColors.electricBlue.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRect(Rect.fromLTWH(0, y - 20, size.width, 40), glow);
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
