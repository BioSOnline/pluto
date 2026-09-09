import '../../features/notes/domain/audio_note.dart';
import '../../pluto_note_repository.dart';

// ─── Duration & Clock Formatting ─────────────────────────────────────────────

String formatPlutoDuration(int durationMs) {
  return formatPlutoClock(Duration(milliseconds: durationMs));
}

String formatPlutoClock(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

  if (hours > 0) {
    return '$hours:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

// ─── Filter Helpers ──────────────────────────────────────────────────────────

bool hasActivePlutoFilters(PlutoNoteFilter filter) {
  return filter.query.trim().isNotEmpty ||
      filter.categoryId != null ||
      filter.tag != null ||
      filter.onlyFavorites ||
      filter.syncStatus != null ||
      filter.createdAfter != null ||
      filter.createdBefore != null;
}

bool isLastDaysFilter(PlutoNoteFilter filter, int days) {
  final createdAfter = filter.createdAfter;
  final createdBefore = filter.createdBefore;
  if (createdAfter == null || createdBefore == null) {
    return false;
  }
  final diff = createdBefore.difference(createdAfter).inDays;
  return (diff - days).abs() <= 1;
}

// ─── Tag Aggregation ─────────────────────────────────────────────────────────

List<String> topPlutoTags(List<PlutoAudioNote> notes, {int limit = 8}) {
  final tagCounts = <String, int>{};
  for (final note in notes) {
    for (final tag in note.tags) {
      tagCounts.update(tag, (count) => count + 1, ifAbsent: () => 1);
    }
  }

  final sortedTags = tagCounts.entries.toList()
    ..sort((left, right) {
      final countComparison = right.value.compareTo(left.value);
      if (countComparison != 0) {
        return countComparison;
      }
      return left.key.compareTo(right.key);
    });

  return sortedTags.take(limit).map((entry) => entry.key).toList();
}
