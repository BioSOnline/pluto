import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../pluto_app_controller.dart';
import '../../pluto_note_repository.dart';
import '../../widgets/pluto_error_banner.dart';
import 'domain/audio_note.dart';
import 'widgets/empty_notes_view.dart';
import 'widgets/note_detail_sheet.dart';
import 'widgets/note_list.dart';
import 'widgets/search_filter_bar.dart';

class PlutoNotesPage extends StatelessWidget {
  const PlutoNotesPage({super.key, required this.controller});

  final PlutoAppController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('notes-page'),
      children: [
        // Search & Category Filters Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: PlutoSearchAndFilters(controller: controller),
        ),

        // Error message banner (if active)
        if (controller.currentErrorMessage != null)
          PlutoErrorBanner(controller: controller),

        // Notes List or Empty State
        Expanded(
          child: controller.visibleNotes.isEmpty
              ? PlutoEmptyNotes(
                  hasActiveFilters: hasActivePlutoFilters(controller.activeFilter),
                  onResetFilters: () => controller.updateFilter(const PlutoNoteFilter()),
                )
              : PlutoNoteList(
                  controller: controller,
                  onNoteTap: (note) => _showNoteDetail(context, controller, note),
                ),
        ),
      ],
    );
  }
}

void _showNoteDetail(
  BuildContext context,
  PlutoAppController controller,
  PlutoAudioNote note,
) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PlutoNoteDetailSheet(controller: controller, note: note),
    ),
  );
}
