import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Full-screen processing overlay with CamScanner-style scan animation.
class ProcessingOverlay extends StatefulWidget {
  const ProcessingOverlay({
    super.key,
    this.message = 'Processing...',
    this.progress,
    this.progressLabel,
    this.showScanAnimation = true,
  });

  final String message;
  final double? progress;
  final String? progressLabel;
  final bool showScanAnimation;

  @override
  State<ProcessingOverlay> createState() => _ProcessingOverlayState();
}

class _ProcessingOverlayState extends State<ProcessingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: widget.message,
      liveRegion: true,
      child: ColoredBox(
        color: colors.scrim.withValues(alpha: 0.58),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(AppSpacing.xxl),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showScanAnimation) ...[
                    SizedBox(
                      width: 120,
                      height: 150,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _ScanBeamPainter(progress: _controller.value),
                            child: child,
                          );
                        },
                        child: Center(
                          child: Icon(
                            Icons.description_outlined,
                            size: 48,
                            color: AppColors.electricBlue.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (widget.progress != null) ...[
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(value: widget.progress),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    widget.message,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.progressLabel != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.progressLabel!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanBeamPainter extends CustomPainter {
  _ScanBeamPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      const Radius.circular(12),
    );

    final border = Paint()
      ..color = AppColors.electricBlue.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(frame, border);

    final y = 16 + (size.height - 32) * progress;
    final beamRect = Rect.fromLTWH(16, y - 10, size.width - 32, 20);
    final beam = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.electricBlue.withValues(alpha: 0.0),
          AppColors.electricBlue.withValues(alpha: 0.45),
          AppColors.cyan.withValues(alpha: 0.55),
          AppColors.electricBlue.withValues(alpha: 0.0),
        ],
      ).createShader(beamRect);
    canvas.drawRect(beamRect, beam);
  }

  @override
  bool shouldRepaint(covariant _ScanBeamPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
