import 'package:flutter/material.dart';
import '../../features/categories/domain/category.dart';
import '../theme/app_colors.dart';

class PlutoCategoryPill extends StatelessWidget {
  const PlutoCategoryPill({
    super.key,
    required this.category,
    this.compact = false,
  });

  final PlutoCategory? category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = category != null
        ? Color(category!.colorValue)
        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);

    final name = category?.name ?? 'Uncategorized';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.32 : 0.22),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
