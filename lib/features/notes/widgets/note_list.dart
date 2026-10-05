import 'package:flutter/material.dart';

import '../../../pluto_app_controller.dart';
import '../domain/audio_note.dart';
import 'note_card.dart';

class PlutoNoteList extends StatelessWidget {
  const PlutoNoteList({
    super.key,
    required this.controller,
    required this.onNoteTap,
  });

  final PlutoAppController controller;
  final void Function(PlutoAudioNote note) onNoteTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      itemCount: controller.visibleNotes.length,
      itemBuilder: (context, index) {
        final note = controller.visibleNotes[index];
        final category = controller.categoryFor(note.categoryId);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PlutoNoteCard(
            controller: controller,
            note: note,
            category: category,
            onTap: () => onNoteTap(note),
          ),
        );
      },
    );
  }
}
