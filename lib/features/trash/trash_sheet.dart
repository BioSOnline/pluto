import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../pluto_app_controller.dart';
import '../../pluto_providers.dart';

class PlutoTrashSheet extends ConsumerWidget {
  const PlutoTrashSheet({super.key, required this.controller});

  final PlutoAppController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = ref.watch(plutoAppControllerProvider);
    final activeController = ref.watch(plutoAppControllerProvider.notifier);

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
          // Drag handle
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

          Row(
            children: [
              Icon(Icons.delete_sweep_rounded, size: 22, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Trash & Recovery',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (appState.trashNotes.isNotEmpty)
                Text(
                  '${appState.trashNotes.length} notes',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (appState.trashNotes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                    ),
                    child: Icon(
                      Icons.restore_from_trash_rounded,
                      size: 28,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Trash is empty',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Deleted notes will appear here for 30 days.',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            ...appState.trashNotes.map((note) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    note.title,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    note.deletedAt == null
                        ? 'Deleted'
                        : 'Deleted ${DateFormat.yMMMd().format(note.deletedAt!)}',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontSize: 12,
                    ),
                  ),
                  leading: IconButton(
                    tooltip: 'Restore note',
                    icon: const Icon(Icons.restore_rounded, color: AppColors.success),
                    onPressed: () => activeController.restoreNote(note.id),
                  ),
                  trailing: IconButton(
                    tooltip: 'Delete permanently',
                    icon: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                    onPressed: () => activeController.permanentlyDeleteNote(note.id),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
