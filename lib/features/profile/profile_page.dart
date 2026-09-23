import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../pluto_app_controller.dart';
import '../auth/auth_sheet.dart';
import '../categories/category_manager_sheet.dart';
import '../trash/trash_sheet.dart';
import 'widgets/account_card.dart';
import 'widgets/settings_sheet.dart';

class PlutoProfilePage extends StatelessWidget {
  const PlutoProfilePage({super.key, required this.controller});

  final PlutoAppController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      key: const ValueKey('profile-page'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        // Top Account Card
        PlutoAccountPanel(
          controller: controller,
          onSignIn: () => _showAuth(context, controller),
        ),

        const SizedBox(height: 20),

        // Section Title: Vault & Preferences
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Vault Management',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Categories Tile
        _buildActionCard(
          context,
          icon: Icons.folder_special_rounded,
          title: 'Categories',
          subtitle: 'Organize notes with colors and tags',
          accentColor: AppColors.primary,
          onTap: () => _showCategoryManager(context, controller),
        ),

        // Trash Tile
        _buildActionCard(
          context,
          icon: Icons.restore_from_trash_rounded,
          title: 'Trash & Archive',
          subtitle: '${controller.trashNotes.length} deleted voice notes',
          accentColor: AppColors.warning,
          onTap: () => _showTrash(context, controller),
        ),

        // Cloud Sync Tile
        _buildActionCard(
          context,
          icon: controller.isSyncing
              ? Icons.sync_rounded
              : Icons.cloud_sync_rounded,
          title: controller.isSyncing ? 'Syncing Vault…' : 'Sync Status',
          subtitle: 'Push offline notes to cloud storage',
          accentColor: AppColors.secondary,
          isLoading: controller.isSyncing,
          onTap: controller.isSyncing ? null : controller.retryFailedSync,
        ),

        // Settings Tile
        _buildActionCard(
          context,
          icon: Icons.tune_rounded,
          title: 'Storage & Settings',
          subtitle: 'Review cache, storage usage, and privacy',
          accentColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          onTap: () => _showSettings(context, controller),
        ),

        const SizedBox(height: 24),

        // Pluto Version Footer
        Center(
          child: Column(
            children: [
              Text(
                'Pluto Audio • v1.0.0',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fast, calm, and dependable voice notes',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                          ),
                        )
                      : Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showAuth(BuildContext context, PlutoAppController controller) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PlutoAuthSheet(controller: controller),
    ),
  );
}

void _showSettings(BuildContext context, PlutoAppController controller) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PlutoSettingsSheet(
        controller: controller,
        onManageCategories: () => _showCategoryManager(context, controller),
      ),
    ),
  );
}

void _showTrash(BuildContext context, PlutoAppController controller) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PlutoTrashSheet(controller: controller),
    ),
  );
}

void _showCategoryManager(BuildContext context, PlutoAppController controller) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PlutoCategoryManagerSheet(controller: controller),
    ),
  );
}
