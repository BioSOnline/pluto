import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

// ─── Legacy Brand Palette Constants (for backward compatibility) ─────────────

const Color plutoInk = AppColors.lightTextPrimary;
const Color plutoMuted = AppColors.lightTextMuted;
const Color plutoSurface = AppColors.lightSurface;
const Color plutoPanel = AppColors.lightCard;
const Color plutoLine = AppColors.lightBorder;
const Color plutoPrimary = AppColors.primary;
const Color plutoPrimaryDark = AppColors.primaryDark;
const Color plutoBackground = AppColors.lightBackground;

// ─── Legacy Category Color Picker Options ────────────────────────────────────

const List<int> plutoCategoryColorOptions = AppColors.categoryColorOptions;

// ─── Legacy ThemeData Builder ────────────────────────────────────────────────

ThemeData buildPlutoTheme() {
  return AppTheme.lightTheme;
}
