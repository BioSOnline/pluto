import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../features/categories/category_manager_sheet.dart';
import '../features/notes/notes_page.dart';
import '../features/profile/profile_page.dart';
import '../features/profile/widgets/settings_sheet.dart';
import '../features/recorder/recorder_sheet.dart';
import '../features/trash/trash_sheet.dart';
import '../pluto_app_controller.dart';
import '../pluto_providers.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) => state = mode;
  void toggle(bool isCurrentlyDark) {
    state = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class PlutoHomeScreen extends ConsumerStatefulWidget {
  const PlutoHomeScreen({super.key});

  @override
  ConsumerState<PlutoHomeScreen> createState() => _PlutoHomeScreenState();
}

class _PlutoHomeScreenState extends ConsumerState<PlutoHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(plutoAppControllerProvider.notifier);
    ref.watch(plutoAppControllerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isHome = _currentIndex == 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.graphic_eq_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isHome ? 'Pluto' : 'Profile',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  isHome ? '48kHz Hi-Fi Workstation' : 'Vault & Settings',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Theme Toggle Button
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && isDark)
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              size: 20,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggle(isDark);
            },
          ),

          // Cloud Sync Button
          IconButton(
            tooltip: 'Retry sync',
            onPressed: controller.isSyncing ? null : controller.retryFailedSync,
            icon: controller.isSyncing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_sync_outlined, size: 22),
          ),

          // Trash Button
          IconButton(
            tooltip: 'Trash',
            onPressed: () => _showTrash(context, controller),
            icon: const Icon(Icons.restore_from_trash_outlined, size: 22),
          ),

          // Settings Button
          IconButton(
            tooltip: 'Settings',
            onPressed: () => _showSettings(context, controller),
            icon: const Icon(Icons.tune_rounded, size: 22),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: isHome
              ? PlutoNotesPage(controller: controller)
              : PlutoProfilePage(controller: controller),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(key: Key('bottom-nav-home'), Icons.mic_none_rounded),
            selectedIcon: Icon(Icons.mic_rounded),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(key: Key('bottom-nav-profile'), Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: isHome
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: controller.recordingState == PlutoRecordingState.idle
                    ? () => _showRecorder(context, controller)
                    : null,
                elevation: 0,
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.mic_rounded, size: 22),
                label: const Text(
                  'Record',
                  style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
                ),
              ),
            )
          : null,
    );
  }
}

void _showRecorder(BuildContext context, PlutoAppController controller) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => PlutoRecorderSheet(controller: controller),
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

void _showCategoryManager(
  BuildContext context,
  PlutoAppController controller,
) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PlutoCategoryManagerSheet(controller: controller),
    ),
  );
}
