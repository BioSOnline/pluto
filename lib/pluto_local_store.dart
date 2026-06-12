import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import 'pluto_note.dart';

class PlutoLocalStore {
  PlutoLocalStore();

  static const _notesBoxName = 'pluto_audio_notes';
  static const _categoriesBoxName = 'pluto_categories';
  static const _settingsBoxName = 'pluto_settings';
  static const _userIdKey = 'activeUserId';
  static const _transcriptionEnabledKey = 'transcriptionEnabled';

  late final Box<dynamic> _notesBox;
  late final Box<dynamic> _categoriesBox;
  late final Box<dynamic> _settingsBox;

  final StreamController<void> _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  Future<void> initialize() async {
    await Hive.initFlutter();
    _notesBox = await Hive.openBox<dynamic>(_notesBoxName);
    _categoriesBox = await Hive.openBox<dynamic>(_categoriesBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
  }

  String get activeUserId {
    return _settingsBox.get(_userIdKey) as String? ?? 'local-user';
  }

  Future<void> setActiveUserId(String userId) async {
    await _settingsBox.put(_userIdKey, userId);
    await ensureDefaultCategories(userId);
    _changes.add(null);
  }

  bool get transcriptionEnabled {
    return _settingsBox.get(_transcriptionEnabledKey) as bool? ?? false;
  }

  Future<void> setTranscriptionEnabled(bool enabled) async {
    await _settingsBox.put(_transcriptionEnabledKey, enabled);
    _changes.add(null);
  }

  Future<void> ensureDefaultCategories(String userId) async {
    final existingCategoryIds = loadCategories()
        .where((category) => category.userId == userId)
        .map((category) => category.id)
        .toSet();

    for (final category in createDefaultPlutoCategories(userId)) {
      if (!existingCategoryIds.contains(category.id)) {
        await _categoriesBox.put(category.id, category.toJson());
      }
    }

    _changes.add(null);
  }

  List<PlutoAudioNote> loadNotes({bool includeDeleted = false}) {
    final notes = _notesBox.values
        .whereType<Map>()
        .map(_mapFromHive)
        .map(PlutoAudioNote.fromJson)
        .where((note) => includeDeleted || !note.isDeleted)
        .toList();

    notes.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return notes;
  }

  PlutoAudioNote? findNote(String noteId) {
    final rawNote = _notesBox.get(noteId);
    if (rawNote is! Map) {
      return null;
    }

    return PlutoAudioNote.fromJson(_mapFromHive(rawNote));
  }

  Future<void> saveNote(PlutoAudioNote note) async {
    await _notesBox.put(note.id, note.toJson());
    _changes.add(null);
  }

  Future<void> saveNotes(List<PlutoAudioNote> notes) async {
    final serializedNotes = <String, Map<String, Object?>>{};
    for (final note in notes) {
      serializedNotes[note.id] = note.toJson();
    }

    await _notesBox.putAll(serializedNotes);
    _changes.add(null);
  }

  List<PlutoCategory> loadCategories() {
    final categories = _categoriesBox.values
        .whereType<Map>()
        .map(_mapFromHive)
        .map(PlutoCategory.fromJson)
        .toList();

    categories.sort((left, right) {
      if (left.isSystemDefault != right.isSystemDefault) {
        return left.isSystemDefault ? -1 : 1;
      }
      return left.name.compareTo(right.name);
    });

    return categories;
  }

  PlutoCategory? findCategory(String categoryId) {
    final rawCategory = _categoriesBox.get(categoryId);
    if (rawCategory is! Map) {
      return null;
    }

    return PlutoCategory.fromJson(_mapFromHive(rawCategory));
  }

  Future<void> saveCategory(PlutoCategory category) async {
    await _categoriesBox.put(category.id, category.toJson());
    _changes.add(null);
  }

  Future<void> softDeleteNote(String noteId) async {
    final note = findNote(noteId);
    if (note == null) {
      throw PlutoLocalStoreException('That note is already gone.');
    }

    await saveNote(note.softDelete());
  }

  Future<void> restoreNote(String noteId) async {
    final note = findNote(noteId);
    if (note == null) {
      throw PlutoLocalStoreException('Cannot restore a note that is missing.');
    }

    await saveNote(note.restore());
  }

  Future<void> permanentlyDeleteNote(String noteId) async {
    await _notesBox.delete(noteId);
    _changes.add(null);
  }

  Future<void> purgeDeletedNotesOlderThan(Duration retentionWindow) async {
    final cutoff = DateTime.now().subtract(retentionWindow);
    final noteIdsToDelete = loadNotes(includeDeleted: true)
        .where((note) {
          final deletedAt = note.deletedAt;
          return deletedAt != null && deletedAt.isBefore(cutoff);
        })
        .map((note) => note.id)
        .toList();

    // trash gets a grace period so accidental deletes are recoverable
    for (final noteId in noteIdsToDelete) {
      await _notesBox.delete(noteId);
    }

    if (noteIdsToDelete.isNotEmpty) {
      _changes.add(null);
    }
  }

  Future<void> clearLocalSession() async {
    await _settingsBox.delete(_userIdKey);
    _changes.add(null);
  }

  Future<void> dispose() async {
    await _changes.close();
  }

  Map<String, Object?> _mapFromHive(Map<dynamic, dynamic> raw) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
}

class PlutoLocalStoreException implements Exception {
  const PlutoLocalStoreException(this.message);

  final String message;

  @override
  String toString() => message;
}
