import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/audio_waveform.dart';
import '../../../core/widgets/category_pill.dart';
import '../../../core/widgets/sync_pill.dart';
import '../../../pluto_app_controller.dart';
import '../domain/audio_note.dart';
import '../../categories/domain/category.dart';

class PlutoNoteCard extends StatefulWidget {
  const PlutoNoteCard({
    super.key,
    required this.controller,
    required this.note,
    required this.category,
    required this.onTap,
  });

  final PlutoAppController controller;
  final PlutoAudioNote note;
  final PlutoCategory? category;
  final VoidCallback onTap;

  @override
  State<PlutoNoteCard> createState() => _PlutoNoteCardState();
}

class _PlutoNoteCardState extends State<PlutoNoteCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playback = widget.controller.playback;
    final isThisNote = playback.noteId == widget.note.id;
    final isPlaying = isThisNote && playback.isPlaying == true;
    final isLoading = isThisNote && playback.isLoading == true;

    final playbackDuration = isThisNote && playback.duration.inMilliseconds > 0
        ? playback.duration
        : Duration(milliseconds: widget.note.durationMs);

    final progress = isThisNote && playbackDuration.inMilliseconds > 0
        ? (playback.position.inMilliseconds / playbackDuration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    final formattedDate = _formatNoteDate(widget.note.createdAt);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isPlaying
            ? (isDark
                ? AppColors.primary.withValues(alpha: 0.10)
                : const Color(0xFFFFF6F4))
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPlaying
              ? AppColors.primary.withValues(alpha: 0.55)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isPlaying ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isPlaying
                ? AppColors.primary.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
            blurRadius: isPlaying ? 16 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: AppColors.primary.withValues(alpha: 0.06),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header: Play Button, Title & Meta, Favorite ───────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tactile Instant-Response Play Button
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => setState(() => _isPressed = true),
                        onTapUp: (_) => setState(() => _isPressed = false),
                        onTapCancel: () => setState(() => _isPressed = false),
                        onTap: () {
                          widget.controller.togglePlayback(widget.note);
                        },
                        child: AnimatedScale(
                          scale: _isPressed ? 0.90 : 1.0,
                          duration: const Duration(milliseconds: 100),
                          curve: Curves.easeOut,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: isPlaying
                                  ? const LinearGradient(
                                      colors: [AppColors.primary, AppColors.primaryLight],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isPlaying
                                  ? null
                                  : (isDark
                                      ? AppColors.darkSurfaceElevated
                                      : AppColors.lightSurfaceElevated),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isPlaying
                                    ? Colors.transparent
                                    : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder),
                                width: 1.2,
                              ),
                              boxShadow: isPlaying
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.40),
                                        blurRadius: 12,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isPlaying ? Colors.white : AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      size: 26,
                                      color: isPlaying
                                          ? Colors.white
                                          : (isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Title & Time info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                formatPlutoDuration(widget.note.durationMs),
                                style: TextStyle(
                                  color: isPlaying
                                      ? AppColors.primary
                                      : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Favorite Button
                    IconButton(
                      tooltip: widget.note.isFavorite == true ? 'Unfavorite' : 'Favorite',
                      onPressed: () => widget.controller.toggleFavorite(widget.note.id),
                      visualDensity: VisualDensity.compact,
                      splashRadius: 20,
                      icon: Icon(
                        widget.note.isFavorite == true
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: widget.note.isFavorite == true
                            ? AppColors.amber
                            : (isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted),
                        size: 22,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ─── Interactive Waveform Scrubber Track ───────────────────
                AudioWaveform(
                  progress: progress,
                  isPlaying: isPlaying,
                  barCount: 38,
                  height: 26,
                  activeColor: AppColors.primary,
                  onSeek: (ratio) {
                    widget.controller.playNote(widget.note);
                    widget.controller.seekPlayback(
                      Duration(
                        milliseconds:
                            (playbackDuration.inMilliseconds * ratio).round(),
                      ),
                    );
                  },
                ),

                // Scrubber Time Row
                if (isThisNote) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatPlutoClock(playback.position),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        formatPlutoClock(playbackDuration),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],

                // ─── Tags (if any) ─────────────────────────────────────────
                if (widget.note.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: widget.note.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : const Color(0xFFF1F3F7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 10),

                // ─── Footer: Category, Sync status, Audio file specs ──────
                Row(
                  children: [
                    PlutoCategoryPill(category: widget.category, compact: true),
                    const SizedBox(width: 8),
                    PlutoSyncPill(status: widget.note.syncStatus, compact: true),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : const Color(0xFFF1F3F7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.note.fileSizeBytes > 0
                            ? '${(widget.note.fileSizeBytes / 1024).ceil()} KB'
                            : 'Hi-Fi Audio',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatNoteDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDay = DateTime(date.year, date.month, date.day);

    if (noteDay == today) {
      return 'Today, ${DateFormat.jm().format(date)}';
    } else if (today.difference(noteDay).inDays == 1) {
      return 'Yesterday, ${DateFormat.jm().format(date)}';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}
