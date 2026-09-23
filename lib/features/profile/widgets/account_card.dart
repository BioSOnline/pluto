import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../pluto_app_controller.dart';
import '../../notes/domain/audio_note.dart';

class PlutoAccountPanel extends StatelessWidget {
  const PlutoAccountPanel({
    super.key,
    required this.controller,
    required this.onSignIn,
  });

  final PlutoAppController controller;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final user = controller.activeUser;
    final totalNotes = controller.allNotes.length;
    final favoriteNotes = controller.allNotes.where((n) => n.isFavorite).length;
    final failedNotes = controller.allNotes
        .where((n) => n.syncStatus == PlutoSyncStatus.failed)
        .length;

    final initial = (user?.displayName.isNotEmpty == true
            ? user!.displayName
            : 'P')
        .characters
        .first
        .toUpperCase();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF312E81), // Deep Indigo
            Color(0xFF1E1B4B), // Cosmic Midnight
            Color(0xFF0E7490), // Deep Cyan
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF312E81).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User Info Row
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user == null
                          ? 'Local Vault'
                          : user.displayName.isEmpty
                              ? 'Signed In'
                              : user.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user == null
                          ? 'Offline-first capture enabled'
                          : user.email.isEmpty
                              ? 'Cloud sync active'
                              : user.email,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (user == null)
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onSignIn,
                  child: const Text('Sign in'),
                )
              else
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withValues(alpha: 0.9),
                  ),
                  onPressed: controller.signOut,
                  child: const Text('Sign out'),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              _buildStatChip(
                icon: Icons.mic_none_rounded,
                label: 'Notes',
                value: '$totalNotes',
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                icon: Icons.star_rounded,
                label: 'Favorites',
                value: '$favoriteNotes',
                accentColor: AppColors.amber,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                icon: failedNotes == 0
                    ? Icons.cloud_done_rounded
                    : Icons.sync_problem_rounded,
                label: 'Sync',
                value: failedNotes == 0 ? 'OK' : '$failedNotes',
                accentColor: failedNotes == 0 ? AppColors.success : AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    Color? accentColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: accentColor ?? Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
