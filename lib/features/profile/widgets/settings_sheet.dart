import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../pluto_app_controller.dart';
import '../../../pluto_note_repository.dart';
import '../../../pluto_providers.dart';
import '../../notes/domain/audio_note.dart';

class PlutoSettingsSheet extends ConsumerWidget {
  const PlutoSettingsSheet({
    super.key,
    required this.controller,
    required this.onManageCategories,
  });

  final PlutoAppController controller;
  final VoidCallback onManageCategories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = ref.watch(plutoAppControllerProvider);
    final activeController = ref.watch(plutoAppControllerProvider.notifier);

    final storageBytes = appState.allNotes.fold<int>(
      0,
      (total, note) => total + note.fileSizeBytes,
    );
    final storageMb = (storageBytes / 1024 / 1024).toStringAsFixed(2);

    final syncedCount = appState.allNotes
        .where((n) => n.syncStatus == PlutoSyncStatus.synced)
        .length;
    final offlineCount = appState.allNotes
        .where((n) => n.syncStatus == PlutoSyncStatus.offline)
        .length;
    final failedCount = appState.allNotes
        .where((n) => n.syncStatus == PlutoSyncStatus.failed)
        .length;
    final uploadingCount = appState.allNotes
        .where((n) => n.syncStatus == PlutoSyncStatus.uploading)
        .length;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Settings & Storage',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),

          // Storage Tile
          _buildSettingsTile(
            context,
            icon: Icons.storage_rounded,
            title: 'Local Storage',
            subtitle: '$storageMb MB used for voice recordings',
            trailing: const Icon(Icons.info_outline, size: 18),
          ),
          const SizedBox(height: 10),

          // Sync Health Tile
          _buildSettingsTile(
            context,
            icon: Icons.cloud_sync_rounded,
            title: 'Sync Health',
            subtitle: 'Synced: $syncedCount • Offline: $offlineCount • Failed: $failedCount • Uploading: $uploadingCount',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              final current = activeController.activeFilter;
              final nextStatus = current.syncStatus == PlutoSyncStatus.failed
                  ? null
                  : PlutoSyncStatus.failed;
              activeController.updateFilter(
                PlutoNoteFilter(
                  query: current.query,
                  categoryId: current.categoryId,
                  tag: current.tag,
                  onlyFavorites: current.onlyFavorites,
                  syncStatus: nextStatus,
                  createdAfter: current.createdAfter,
                  createdBefore: current.createdBefore,
                ),
              );
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 10),

          // Categories Tile
          _buildSettingsTile(
            context,
            icon: Icons.folder_special_rounded,
            title: 'Manage Categories',
            subtitle: 'Create, rename, or color-code note categories',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onManageCategories,
          ),
          const SizedBox(height: 10),

          // Privacy Tile
          _buildSettingsTile(
            context,
            icon: Icons.shield_outlined,
            title: 'Privacy & Offline Guarantee',
            subtitle: 'Audio stays strictly local until cloud sync succeeds',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontSize: 12,
          ),
        ),
        trailing: trailing,
      ),
    );
  }
}
