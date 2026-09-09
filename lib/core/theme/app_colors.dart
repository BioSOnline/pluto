import 'package:flutter/material.dart';

/// Studio-grade design palette for Pluto Audio Workstation.
class AppColors {
  AppColors._();

  // ─── Primary Studio Audio Brand Colors ────────────────────────────────────
  static const Color primary = Color(0xFFFF5238); // Studio Vermilion / Record Signal
  static const Color primaryLight = Color(0xFFFF725C);
  static const Color primaryDark = Color(0xFFDE371E);
  static const Color secondary = Color(0xFF14B8A6); // Precision Calibrated Teal
  static const Color accent = Color(0xFF6366F1); // Deep Studio Indigo
  static const Color amber = Color(0xFFF59E0B); // Analog VU Gold

  // ─── Dark Theme Surfaces (Studio Obsidian & Carbon) ──────────────────────
  static const Color darkBackground = Color(0xFF0C0E14);
  static const Color darkSurface = Color(0xFF131722);
  static const Color darkSurfaceElevated = Color(0xFF1B202E);
  static const Color darkCard = Color(0xFF161A26);
  static const Color darkBorder = Color(0xFF262D3D);
  static const Color darkBorderSubtle = Color(0xFF1D2230);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // ─── Light Theme Surfaces (Clean Architectural Slate) ────────────────────
  static const Color lightBackground = Color(0xFFF8F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderSubtle = Color(0xFFEDF2F7);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // ─── Semantic Signal Colors ───────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ─── Curated Category Color Options ───────────────────────────────────────
  static const List<int> categoryColorOptions = [
    0xFFFF5238, // Studio Vermilion
    0xFF14B8A6, // Calibrated Teal
    0xFF10B981, // Studio Emerald
    0xFFF59E0B, // VU Gold
    0xFF6366F1, // Slate Indigo
    0xFFEC4899, // Studio Coral
    0xFF64748B, // Neutral Carbon
  ];
}
