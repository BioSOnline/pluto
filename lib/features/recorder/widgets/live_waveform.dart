import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Real-time pulsing soundwave bars for recording visualizer.
class LiveWaveform extends StatefulWidget {
  const LiveWaveform({
    super.key,
    required this.isRecording,
    required this.isPaused,
    this.barCount = 20,
    this.height = 36,
  });

  final bool isRecording;
  final bool isPaused;
  final int barCount;
  final double height;

  @override
  State<LiveWaveform> createState() => _LiveWaveformState();
}

class _LiveWaveformState extends State<LiveWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    if (widget.isRecording && !widget.isPaused) {
      _animController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LiveWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !widget.isPaused && !_animController.isAnimating) {
      _animController.repeat(reverse: true);
    } else if ((!widget.isRecording || widget.isPaused) &&
        _animController.isAnimating) {
      _animController.stop();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.isRecording && !widget.isPaused
        ? AppColors.primary
        : widget.isPaused
            ? AppColors.warning
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final animValue = _animController.value;

        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              final phase = sin(index * 0.5 + animValue * pi * 2);
              final dynamicFactor = widget.isRecording && !widget.isPaused
                  ? (0.25 + 0.75 * ((phase + 1) / 2))
                  : (widget.isPaused ? 0.35 : 0.2);
              final barHeight = (widget.height * dynamicFactor).clamp(6.0, widget.height);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 3.5,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: widget.isRecording && !widget.isPaused
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
