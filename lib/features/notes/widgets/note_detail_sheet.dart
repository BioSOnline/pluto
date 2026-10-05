import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/audio_waveform.dart';
import '../../../core/widgets/category_pill.dart';
import '../../../core/widgets/sync_pill.dart';
import '../../../pluto_app_controller.dart';
import '../../../pluto_providers.dart';
import '../domain/audio_note.dart';

class PlutoNoteDetailSheet extends ConsumerStatefulWidget {
  const PlutoNoteDetailSheet({
    super.key,
    required this.controller,
    required this.note,
  });

  final PlutoAppController controller;
  final PlutoAudioNote note;

  @override
  ConsumerState<PlutoNoteDetailSheet> createState() => _PlutoNoteDetailSheetState();
}

class _PlutoNoteDetailSheetState extends ConsumerState<PlutoNoteDetailSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _tagsController;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _tagsController = TextEditingController(text: widget.note.tags.join(', '));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _cycleSpeed() {
    final speeds = [1.0, 1.25, 1.5, 2.0];
    final currentIndex = speeds.indexOf(_playbackSpeed);
    final nextSpeed = speeds[(currentIndex + 1) % speeds.length];
    setState(() {
      _playbackSpeed = nextSpeed;
    });
    widget.controller.setPlaybackSpeed(nextSpeed);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = ref.watch(plutoAppControllerProvider);
    final controller = ref.watch(plutoAppControllerProvider.notifier);
    final note = _findCurrentNote(controller, widget.note.id) ?? widget.note;
    final category = controller.categoryFor(note.categoryId);
    final playback = appState.playback;
    final isThisNotePlaying = playback.noteId == note.id && playback.isPlaying == true;
    final isLoaded = playback.noteId == note.id;

    final playbackDuration = playback.duration.inMilliseconds == 0
        ? Duration(milliseconds: note.durationMs)
        : playback.duration;

    final progress = isLoaded && playbackDuration.inMilliseconds > 0
        ? (playback.position.inMilliseconds / playbackDuration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Center drag handle
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

            // Top action bar
            Row(
              children: [
                PlutoCategoryPill(category: category),
                const SizedBox(width: 8),
                PlutoSyncPill(status: note.syncStatus),
                const Spacer(),
                IconButton(
                  tooltip: note.isFavorite == true ? 'Unfavorite' : 'Favorite',
                  onPressed: () => widget.controller.toggleFavorite(note.id),
                  icon: Icon(
                    note.isFavorite == true ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: note.isFavorite == true ? AppColors.amber : null,
                  ),
                ),
                IconButton(
                  tooltip: 'Share audio',
                  onPressed: () => _shareNoteAudio(note),
                  icon: const Icon(Icons.share_outlined, size: 20),
                ),
                IconButton(
                  tooltip: 'Delete note',
                  onPressed: () async {
                    await widget.controller.deleteNote(note.id);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Audio Player Console Box
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightSurfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isThisNotePlaying
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                boxShadow: isThisNotePlaying
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  // Play/Pause & Speed Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Play / Pause Circle
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            widget.controller.togglePlayback(note);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: isThisNotePlaying
                                  ? const LinearGradient(
                                      colors: [AppColors.primary, AppColors.primaryLight],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isThisNotePlaying
                                  ? null
                                  : (isDark
                                      ? AppColors.darkSurfaceElevated
                                      : AppColors.lightSurfaceElevated),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: isThisNotePlaying ? 0.38 : 0.08,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: (playback.isLoading && isLoaded)
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      isThisNotePlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      size: 32,
                                      color: isThisNotePlaying
                                          ? Colors.white
                                          : (isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      // Time Display
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isLoaded
                                ? formatPlutoClock(playback.position)
                                : '00:00',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            formatPlutoClock(playbackDuration),
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Large Interactive Waveform Scrubber
                  AudioWaveform(
                    progress: progress,
                    isPlaying: isThisNotePlaying,
                    barCount: 40,
                    height: 42,
                    activeColor: AppColors.primary,
                    onSeek: (ratio) {
                      widget.controller.seekPlayback(
                        Duration(
                          milliseconds: (playbackDuration.inMilliseconds * ratio).round(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Speed Control Badge
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: _cycleSpeed,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Text(
                          '${_playbackSpeed}x Speed',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Metadata & Edit Fields
            TextField(
              controller: _titleController,
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
              ),
              onSubmitted: (value) => widget.controller.renameNote(note.id, value),
            ),

            const SizedBox(height: 12),

            // Category Picker
            DropdownButtonFormField<String>(
              initialValue: note.categoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.folder_outlined, size: 20),
              ),
              items: widget.controller.categories.map((cat) {
                return DropdownMenuItem(
                  value: cat.id,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color(cat.colorValue),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(cat.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (catId) {
                if (catId != null) {
                  widget.controller.moveNoteToCategory(note.id, catId);
                }
              },
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma-separated)',
                hintText: 'meeting, ideas, quick note',
                prefixIcon: Icon(Icons.tag_rounded, size: 20),
              ),
              onSubmitted: (value) => widget.controller.updateNoteTags(
                note.id,
                value.split(','),
              ),
            ),

            if (note.transcript != null && note.transcript!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.subtitles_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Transcript',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      note.transcript!,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _shareNoteAudio(PlutoAudioNote note) async {
    if (kIsWeb) {
      await SharePlus.instance.share(ShareParams(text: note.title));
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        text: note.title,
        files: [XFile(note.localFilePath)],
      ),
    );
  }
}

PlutoAudioNote? _findCurrentNote(
  PlutoAppController controller,
  String noteId,
) {
  for (final note in [
    ...controller.visibleNotes,
    ...controller.trashNotes,
  ]) {
    if (note.id == noteId) return note;
  }
  return null;
}
