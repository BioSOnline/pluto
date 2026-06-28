import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

import 'pluto_audio_service.dart';
import 'pluto_cloud_sync_service.dart';
import 'pluto_local_store.dart';
import 'pluto_note.dart';

class PlutoNoteRepository {
  PlutoNoteRepository({
    required PlutoLocalStore localStore,
    required PlutoCloudSyncService cloudSyncService,
    Uuid? uuid,
  })  : _localStore = localStore,
        _cloudSyncService = cloudSyncService,
        _uuid = uuid ?? const Uuid();

  final PlutoLocalStore _localStore;
  final PlutoCloudSyncService _cloudSyncService;
  final Uuid _uuid;

  Stream<void> get changes => _localStore.changes;
  Stream<List<ConnectivityResult>> get connectivityChanges =>
      _cloudSyncService.connectivityChanges;

  Future<void> initializeForUser(String userId) async {
    await _localStore.setActiveUserId(userId);
    await _localStore.ensureDefaultCategories(userId);
    await _localStore.purgeDeletedNotesOlderThan(const Duration(days: 30));
  }

  List<PlutoAudioNote> loadVisibleNotes() {
    return _localStore.loadNotes();
  }

  List<PlutoAudioNote> loadTrash() {
    return _localStore
        .loadNotes(includeDeleted: true)
        .where((note) => note.isDeleted)
        .toList();
  }

  List<PlutoCategory> loadCategories() {
    return _localStore.loadCategories();
  }

  PlutoAudioNote? findNote(String noteId) {
    return _localStore.findNote(noteId);
  }

  PlutoCategory? findCategory(String categoryId) {
    return _localStore.findCategory(categoryId);
  }

  Future<PlutoAudioNote> saveFinishedRecording({
    required PlutoFinishedRecording recording,
    required String requestedTitle,
    required List<String> requestedTags,
    String? transcript,
  }) async {
    final now = DateTime.now();
    final tags = _cleanRequestedTags(requestedTags);
    final title = requestedTitle.trim().isEmpty
        ? createFallbackNoteTitle(now)
        : requestedTitle.trim();
    final categoryId = suggestPlutoCategoryId(
      title: title,
      tags: tags,
      transcript: transcript,
    );

    final note = PlutoAudioNote(
      id: _uuid.v4(),
      userId: _localStore.activeUserId,
      title: title,
      categoryId: categoryId,
      tags: tags,
      durationMs: recording.duration.inMilliseconds,
      fileSizeBytes: recording.fileSizeBytes,
      localFilePath: recording.filePath,
      cloudFileUrl: null,
      transcript: transcript,
      isFavorite: false,
      syncStatus: PlutoSyncStatus.offline,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
    );

    await _localStore.saveNote(note);
    return _syncNoteIfAllowed(note);
  }

  Future<PlutoAudioNote> renameNote(String noteId, String nextTitle) async {
    final note = _requireNote(noteId);
    final renamedNote = note.rename(nextTitle);
    await _localStore.saveNote(renamedNote);
    return _syncNoteIfAllowed(renamedNote);
  }

  Future<PlutoAudioNote> moveNoteToCategory(
    String noteId,
    String categoryId,
  ) async {
    final note = _requireNote(noteId);
    final category = _localStore.findCategory(categoryId);
    if (category == null) {
      throw const PlutoNoteRepositoryException('That category does not exist.');
    }

    final movedNote = note.moveToCategory(categoryId);
    await _localStore.saveNote(movedNote);
    return _syncNoteIfAllowed(movedNote);
  }

  Future<PlutoAudioNote> updateNoteTags(
    String noteId,
    List<String> tags,
  ) async {
    final note = _requireNote(noteId);
    final taggedNote = note.retag(tags);
    await _localStore.saveNote(taggedNote);
    return _syncNoteIfAllowed(taggedNote);
  }

  Future<PlutoAudioNote> toggleFavorite(String noteId) async {
    final note = _requireNote(noteId);
    final favoriteNote = note.toggleFavorite();
    await _localStore.saveNote(favoriteNote);
    return _syncNoteIfAllowed(favoriteNote);
  }

  Future<void> deleteNote(String noteId) async {
    final note = _requireNote(noteId);
    final deletedNote = note.softDelete();
    await _localStore.saveNote(deletedNote);

    try {
      await _cloudSyncService.deleteCloudNote(deletedNote);
      await _localStore.saveNote(deletedNote.markSynced());
    } on PlutoCloudSyncException {
      await _localStore.saveNote(deletedNote.markSyncFailed());
    }
  }

  Future<void> restoreNote(String noteId) async {
    final note = _requireNote(noteId);
    final restoredNote = note.restore();
    await _localStore.saveNote(restoredNote);
    await _syncNoteIfAllowed(restoredNote);
  }

  Future<void> permanentlyDeleteNote(String noteId) async {
    final note = _requireNote(noteId);

    try {
      await _cloudSyncService.permanentlyDeleteCloudNote(note);
    } on PlutoCloudSyncException {
      if (!_canUseCloud(note.userId)) {
        await _localStore.permanentlyDeleteNote(noteId);
        return;
      }
      rethrow;
    }

    await _localStore.permanentlyDeleteNote(noteId);
  }

  Future<PlutoCategory> createCategory({
    required String name,
    required int colorValue,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const PlutoNoteRepositoryException('Category name cannot be empty.');
    }

    final now = DateTime.now();
    final category = PlutoCategory(
      id: _uuid.v4(),
      userId: _localStore.activeUserId,
      name: trimmedName,
      colorValue: colorValue,
      isSystemDefault: false,
      createdAt: now,
      updatedAt: now,
    );

    await _localStore.saveCategory(category);
    await _syncCategoryIfAllowed(category);
    return category;
  }

  Future<PlutoCategory> renameCategory(
    String categoryId,
    String nextName,
  ) async {
    final category = _localStore.findCategory(categoryId);
    if (category == null) {
      throw const PlutoNoteRepositoryException('That category does not exist.');
    }
    if (category.isSystemDefault) {
      throw const PlutoNoteRepositoryException(
        'Default Pluto categories cannot be renamed.',
      );
    }

    final renamedCategory = category.rename(nextName);
    await _localStore.saveCategory(renamedCategory);
    await _syncCategoryIfAllowed(renamedCategory);
    return renamedCategory;
  }

  List<PlutoAudioNote> searchNotes(PlutoNoteFilter filter) {
    final categoriesById = {
      for (final category in _localStore.loadCategories()) category.id: category,
    };

    return _localStore.loadNotes().where((note) {
      if (!note.matchesSearch(filter.query, categoriesById[note.categoryId])) {
        return false;
      }
      if (filter.categoryId != null && note.categoryId != filter.categoryId) {
        return false;
      }
      if (filter.tag != null && !note.tags.contains(filter.tag)) {
        return false;
      }
      if (filter.onlyFavorites && !note.isFavorite) {
        return false;
      }
      if (filter.syncStatus != null && note.syncStatus != filter.syncStatus) {
        return false;
      }
      if (filter.createdAfter != null &&
          note.createdAt.isBefore(filter.createdAfter!)) {
        return false;
      }
      if (filter.createdBefore != null &&
          note.createdAt.isAfter(filter.createdBefore!)) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> refreshFromCloud(String userId) async {
    if (!_canUseCloud(userId)) {
      return;
    }

    final remoteNotes = await _cloudSyncService.pullRemoteNotes(userId);
    final remoteCategories = await _cloudSyncService.pullRemoteCategories(
      userId,
    );
    final mergedNotes = _cloudSyncService.mergeRemoteNotes(
      localNotes: _localStore.loadNotes(includeDeleted: true),
      remoteNotes: remoteNotes,
    );
    final mergedCategories = _cloudSyncService.mergeRemoteCategories(
      localCategories: _localStore.loadCategories(),
      remoteCategories: remoteCategories,
    );

    await _localStore.saveNotes(mergedNotes);
    for (final category in mergedCategories) {
      await _localStore.saveCategory(category);
    }
  }

  Future<void> retryFailedSync() async {
    final retryableNotes = _localStore
        .loadNotes(includeDeleted: true)
        .where((note) => note.canRetrySync)
        .toList();

    await Future.wait(retryableNotes.map(_syncNoteIfAllowed));
  }

  Future<void> syncPendingNotes() async {
    final pendingNotes = _localStore
        .loadNotes(includeDeleted: true)
        .where((note) => note.syncStatus != PlutoSyncStatus.synced)
        .toList();

    await Future.wait(pendingNotes.map(_syncNoteIfAllowed));
  }

  Future<PlutoAudioNote> _syncNoteIfAllowed(PlutoAudioNote note) async {
    if (!_canUseCloud(note.userId)) {
      return note;
    }

    final uploadingNote = note.markUploading();
    await _localStore.saveNote(uploadingNote);

    try {
      final syncedNote = await _cloudSyncService.uploadAudioNote(uploadingNote);
      await _localStore.saveNote(syncedNote);
      return syncedNote;
    } on PlutoCloudSyncException {
      final failedNote = note.markSyncFailed();
      await _localStore.saveNote(failedNote);
      return failedNote;
    }
  }

  Future<void> _syncCategoryIfAllowed(PlutoCategory category) async {
    if (!_canUseCloud(category.userId)) {
      return;
    }

    try {
      await _cloudSyncService.syncCategory(category);
    } on PlutoCloudSyncException {
      // category edits are tiny, keeping them local beats blocking note capture
    }
  }

  bool _canUseCloud(String userId) {
    return userId.isNotEmpty && userId != 'local-user';
  }

  PlutoAudioNote _requireNote(String noteId) {
    final note = _localStore.findNote(noteId);
    if (note == null) {
      throw const PlutoNoteRepositoryException('That note could not be found.');
    }

    return note;
  }

  List<String> _cleanRequestedTags(List<String> tags) {
    final cleanedTags = tags
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
    cleanedTags.sort();
    return cleanedTags;
  }
}

class PlutoNoteFilter {
  const PlutoNoteFilter({
    this.query = '',
    this.categoryId,
    this.tag,
    this.onlyFavorites = false,
    this.syncStatus,
    this.createdAfter,
    this.createdBefore,
  });

  final String query;
  final String? categoryId;
  final String? tag;
  final bool onlyFavorites;
  final PlutoSyncStatus? syncStatus;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
}

class PlutoNoteRepositoryException implements Exception {
  const PlutoNoteRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
