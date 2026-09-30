import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Professional studio record controller button with tactile feedback,
/// metallic rim detailing, and warm analog breathing aura.
class PlutoRecordingOrb extends StatefulWidget {
  const PlutoRecordingOrb({
    super.key,
    required this.isRecording,
    required this.isPaused,
    required this.child,
    this.diameter = 160,
  });

  final bool isRecording;
  final bool isPaused;
  final Widget child;
  final double diameter;

  @override
  State<PlutoRecordingOrb> createState() => _PlutoRecordingOrbState();
}

class _PlutoRecordingOrbState extends State<PlutoRecordingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutCubic,
    );

    if (widget.isRecording && !widget.isPaused) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PlutoRecordingOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !widget.isPaused && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if ((!widget.isRecording || widget.isPaused) &&
        _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.animateTo(0, duration: const Duration(milliseconds: 250));
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        final pulse = _pulseAnimation.value;
        final spread = 12.0 * pulse;

        Color auraColor;
        if (widget.isRecording && !widget.isPaused) {
          auraColor = AppColors.primary;
        } else if (widget.isPaused) {
          auraColor = AppColors.warning;
        } else {
          auraColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: widget.diameter + 32,
            height: widget.diameter + 32,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Analog breathing halo
                if (widget.isRecording && !widget.isPaused)
                  Container(
                    width: widget.diameter + spread * 1.8,
                    height: widget.diameter + spread * 1.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: auraColor.withValues(alpha: 0.14 * (1.0 - pulse * 0.4)),
                    ),
                  ),

                // Precision studio rim
                Container(
                  width: widget.diameter,
                  height: widget.diameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                    border: Border.all(
                      color: (widget.isRecording && !widget.isPaused)
                          ? AppColors.primary.withValues(alpha: 0.8)
                          : (widget.isPaused
                              ? AppColors.warning
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                      width: widget.isRecording ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.isRecording && !widget.isPaused)
                            ? AppColors.primary.withValues(alpha: 0.28)
                            : Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                        blurRadius: widget.isRecording ? 22 : 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(child: widget.child),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
