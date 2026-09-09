import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../../pluto_app_controller.dart';

class PlutoErrorBanner extends StatelessWidget {
  const PlutoErrorBanner({super.key, required this.controller});

  final PlutoAppController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.error.withValues(alpha: 0.15)
              : AppColors.errorLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.error.withValues(alpha: isDark ? 0.4 : 0.3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                controller.currentErrorMessage ?? '',
                style: TextStyle(
                  color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Dismiss',
              visualDensity: VisualDensity.compact,
              onPressed: controller.clearError,
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
