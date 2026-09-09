import 'package:flutter/material.dart';
import '../../features/notes/domain/audio_note.dart';
import '../theme/app_colors.dart';

class PlutoSyncPill extends StatelessWidget {
  const PlutoSyncPill({
    super.key,
    required this.status,
    this.compact = false,
  });

  final PlutoSyncStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (label, color, iconData) = switch (status) {
      PlutoSyncStatus.synced => (
        'Synced',
        AppColors.success,
        Icons.cloud_done_rounded,
      ),
      PlutoSyncStatus.uploading => (
        'Uploading',
        AppColors.info,
        Icons.cloud_upload_rounded,
      ),
      PlutoSyncStatus.offline => (
        'Offline',
        AppColors.darkTextMuted,
        Icons.cloud_off_rounded,
      ),
      PlutoSyncStatus.failed => (
        'Failed',
        AppColors.error,
        Icons.sync_problem_rounded,
      ),
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
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
          if (status == PlutoSyncStatus.uploading) ...[
            SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(width: 5),
          ] else ...[
            Icon(iconData, size: compact ? 12 : 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
