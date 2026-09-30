import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../pluto_app_controller.dart';
import '../../pluto_providers.dart';
import '../notes/domain/audio_note.dart';
import 'widgets/live_waveform.dart';
import 'widgets/recording_orb.dart';

class PlutoRecorderSheet extends ConsumerStatefulWidget {
  const PlutoRecorderSheet({super.key, required this.controller});

  final PlutoAppController controller;

  @override
  ConsumerState<PlutoRecorderSheet> createState() => _PlutoRecorderSheetState();
}

class _PlutoRecorderSheetState extends ConsumerState<PlutoRecorderSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  String _suggestedCategory = 'uncategorized';

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_updateSuggestedCategory);
    _tagsController.addListener(_updateSuggestedCategory);
  }

  void _updateSuggestedCategory() {
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final suggested = suggestPlutoCategoryId(
      title: _titleController.text,
      tags: tags,
    );

    if (suggested != _suggestedCategory) {
      setState(() {
        _suggestedCategory = suggested;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(PlutoAppController controller) async {
    final title = _titleController.text.trim();
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final savedNote = await controller.stopAndSaveRecording(
      title: title,
      tags: tags,
    );

    if (savedNote != null && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = ref.watch(plutoAppControllerProvider);
    final controller = ref.watch(plutoAppControllerProvider.notifier);

    final isRecording =
        appState.recordingState == PlutoRecordingState.recording;
    final isPaused =
        appState.recordingState == PlutoRecordingState.paused;
    final isSaving =
        appState.recordingState == PlutoRecordingState.saving;
    final canSave = isRecording || isPaused;
    final isBusy = appState.isBusy == true;

    final statusLabel = isRecording
        ? 'Recording now'
        : isPaused
            ? 'Paused'
            : isSaving
                ? 'Saving…'
                : 'Ready to capture';

    final statusColor = isRecording
        ? AppColors.error
        : isPaused
            ? AppColors.warning
            : isSaving
                ? AppColors.info
                : AppColors.primary;

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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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

            // Sheet Header Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Studio Recording',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withValues(alpha: isDark ? 0.4 : 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Studio Hi-Fi Indicator
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.graphic_eq_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '48 kHz • 256 kbps Stereo Hi-Fi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Cosmic Recording Orb (interactive tap)
            Center(
              child: GestureDetector(
                onTap: isBusy || isSaving
                    ? null
                    : isRecording
                        ? controller.pauseRecording
                        : isPaused
                            ? controller.resumeRecording
                            : controller.startRecording,
                child: PlutoRecordingOrb(
                  isRecording: isRecording,
                  isPaused: isPaused,
                  diameter: 170,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatPlutoClock(appState.recordingDuration),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontSize: 38,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRecording
                            ? 'TAP TO PAUSE'
                            : (isPaused ? 'TAP TO RESUME' : 'TAP TO RECORD'),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Live Animated Soundwave Bars
            LiveWaveform(
              isRecording: isRecording,
              isPaused: isPaused,
              barCount: 24,
              height: 28,
            ),

            const SizedBox(height: 18),

            // Primary Control Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Record / Pause / Resume Button
                FilledButton.icon(
                  onPressed: isBusy || isSaving
                      ? null
                      : isRecording
                          ? controller.pauseRecording
                          : isPaused
                              ? controller.resumeRecording
                              : controller.startRecording,
                  icon: Icon(
                    isRecording
                        ? Icons.pause_rounded
                        : isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.mic_rounded,
                    size: 20,
                  ),
                  label: Text(
                    isRecording
                        ? 'Pause'
                        : isPaused
                            ? 'Resume'
                            : 'Start Recording',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: isRecording ? AppColors.warning : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                if (canSave) ...[
                  const SizedBox(width: 10),
                  // Stop & Save Shortcut
                  FilledButton.icon(
                    onPressed: isBusy || isSaving
                        ? null
                        : () => _handleSave(controller),
                    icon: isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.stop_rounded, size: 20),
                    label: Text(isSaving ? 'Saving…' : 'Stop & Save'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Cancel Button
                  OutlinedButton.icon(
                    onPressed: isBusy || isSaving
                        ? null
                        : controller.cancelRecording,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // Title Input
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Note title (optional)',
                hintText: 'e.g. Brainstorm, Meeting notes, Lecture summary',
                prefixIcon: const Icon(Icons.title_rounded, size: 20),
                suffixIcon: _suggestedCategory != 'uncategorized'
                    ? Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: const Icon(Icons.auto_awesome, size: 12, color: AppColors.amber),
                          label: Text(
                            _suggestedCategory.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 10),

            // Tags Input
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                hintText: 'meeting, ideas, reminder',
                prefixIcon: Icon(Icons.tag_rounded, size: 20),
              ),
            ),

            const SizedBox(height: 16),

            // Save Note Button
            FilledButton.icon(
              onPressed: canSave && !isBusy && !isSaving
                  ? () => _handleSave(controller)
                  : null,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 20),
              label: Text(isSaving ? 'Saving note…' : 'Save voice note'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
