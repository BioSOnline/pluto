import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto/core/utils/formatters.dart';
import 'package:pluto/core/widgets/audio_waveform.dart';
import 'package:pluto/core/widgets/category_pill.dart';
import 'package:pluto/core/widgets/sync_pill.dart';
import 'package:pluto/features/categories/domain/category.dart';
import 'package:pluto/features/notes/domain/audio_note.dart';
import 'package:pluto/pluto_app_controller.dart';

void main() {
  group('Formatters & Domain logic', () {
    test('formatPlutoClock formats seconds and minutes correctly', () {
      expect(formatPlutoClock(const Duration(seconds: 45)), '00:45');
      expect(formatPlutoClock(const Duration(minutes: 3, seconds: 12)), '03:12');
      expect(formatPlutoClock(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
    });

    test('suggestPlutoCategoryId categorizes keywords accurately', () {
      expect(
        suggestPlutoCategoryId(title: 'Team meeting notes', tags: []),
        'work',
      );
      expect(
        suggestPlutoCategoryId(title: 'Physics lecture revision', tags: []),
        'study',
      );
      expect(
        suggestPlutoCategoryId(title: 'Grocery list', tags: ['buy', 'milk']),
        'reminders',
      );
      expect(
        suggestPlutoCategoryId(title: 'Random thought', tags: []),
        plutoUncategorizedCategoryId,
      );
    });
  });

  group('UI Components', () {
    testWidgets('AudioWaveform renders barCount bars', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AudioWaveform(
              progress: 0.5,
              isPlaying: true,
              barCount: 20,
            ),
          ),
        ),
      );

      expect(find.byType(AudioWaveform), findsOneWidget);
    });

    testWidgets('CategoryPill renders category name', (tester) async {
      final category = PlutoCategory(
        id: 'work',
        userId: 'u1',
        name: 'Work Project',
        colorValue: 0xFF6366F1,
        isSystemDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlutoCategoryPill(category: category),
          ),
        ),
      );

      expect(find.text('Work Project'), findsOneWidget);
    });

    testWidgets('SyncPill renders correct label for status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlutoSyncPill(status: PlutoSyncStatus.synced),
          ),
        ),
      );

      expect(find.text('Synced'), findsOneWidget);
    });

    test('PlutoPlaybackSnapshot maintains speed and loading states correctly', () {
      const snapshot = PlutoPlaybackSnapshot(
        noteId: 'n1',
        isPlaying: true,
        isLoading: false,
        speed: 1.25,
      );
      expect(snapshot.isPlaying, isTrue);
      expect(snapshot.isLoading, isFalse);
      expect(snapshot.speed, 1.25);

      final updated = snapshot.copyWith(speed: 1.5, isLoading: true);
      expect(updated.speed, 1.5);
      expect(updated.isLoading, isTrue);
      expect(updated.noteId, 'n1');
    });
  });
}
