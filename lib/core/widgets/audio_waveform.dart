import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// High-performance, tactile audio waveform scrubber.
/// Uses [CustomPainter] for 60/120 FPS hardware-accelerated rendering and zero jank.
class AudioWaveform extends StatelessWidget {
  const AudioWaveform({
    super.key,
    required this.progress,
    required this.isPlaying,
    this.barCount = 36,
    this.height = 28,
    this.activeColor = AppColors.primary,
    this.inactiveColor,
    this.onSeek,
  });

  final double progress;
  final bool isPlaying;
  final int barCount;
  final double height;
  final Color activeColor;
  final Color? inactiveColor;
  final ValueChanged<double>? onSeek;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultInactiveColor = isDark
        ? AppColors.darkBorder
        : AppColors.lightBorder;
    final resolvedInactiveColor = inactiveColor ?? defaultInactiveColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        return MouseRegion(
          cursor: onSeek != null ? SystemMouseCursors.click : MouseCursor.defer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: onSeek != null
                ? (details) {
                    final ratio = (details.localPosition.dx / totalWidth)
                        .clamp(0.0, 1.0);
                    onSeek!(ratio);
                  }
                : null,
            onHorizontalDragUpdate: onSeek != null
                ? (details) {
                    final ratio = (details.localPosition.dx / totalWidth)
                        .clamp(0.0, 1.0);
                    onSeek!(ratio);
                  }
                : null,
            child: SizedBox(
              width: totalWidth,
              height: height,
              child: CustomPaint(
                painter: _WaveformPainter(
                  progress: progress,
                  isPlaying: isPlaying,
                  barCount: barCount,
                  activeColor: activeColor,
                  inactiveColor: resolvedInactiveColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.progress,
    required this.isPlaying,
    required this.barCount,
    required this.activeColor,
    required this.inactiveColor,
  });

  final double progress;
  final bool isPlaying;
  final int barCount;
  final Color activeColor;
  final Color inactiveColor;

  static double _barHeightFactor(int index) {
    // Harmonic audio envelope: blends natural voice peaks and valleys
    final sinA = (sin(index * 0.38) + 1) * 0.35;
    final sinB = (cos(index * 0.72) + 1) * 0.25;
    final noise = ((index * 19 + 7) % 23) / 60.0;
    return (0.18 + sinA + sinB + noise).clamp(0.18, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (barCount <= 0 || size.width <= 0) return;

    final barWidth = (size.width / (barCount * 1.55)).clamp(2.0, 5.0);
    final gap = (size.width - (barCount * barWidth)) / (barCount - 1);
    final centerY = size.height / 2;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;

    for (var i = 0; i < barCount; i++) {
      final x = i * (barWidth + gap);
      final factor = _barHeightFactor(i);
      final barH = (size.height * factor).clamp(4.0, size.height);
      final top = centerY - (barH / 2);

      final barRatio = (i + 0.5) / barCount;
      final isPlayed = barRatio <= progress;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barH),
        const Radius.circular(99),
      );

      canvas.drawRRect(rrect, isPlayed ? activePaint : inactivePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.barCount != barCount ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
