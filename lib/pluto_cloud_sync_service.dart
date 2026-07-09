import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'pluto_audio_file.dart';
import 'pluto_note.dart';

class PlutoCloudSyncService {
  PlutoCloudSyncService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    Connectivity? connectivity,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _connectivity = connectivity ?? Connectivity();

  PlutoCloudSyncService.test()
    : _firestore = null,
      _storage = null,
      _connectivity = null;

  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;
  final Connectivity? _connectivity;

  Stream<List<ConnectivityResult>> get connectivityChanges {
    final connectivity = _connectivity;
    if (connectivity == null) {
      return const Stream.empty();
    }
    return connectivity.onConnectivityChanged;
  }

  Future<bool> hasNetwork() async {
    final connectivity = _connectivity;
    if (connectivity == null) {
      return false;
    }

    final connectivityResults = await connectivity.checkConnectivity();
    return connectivityResults.any(
      (result) => result != ConnectivityResult.none,
    );
  }

  Future<PlutoAudioNote> uploadAudioNote(PlutoAudioNote note) async {
    final storage = _storageInstance();
    if (!await hasNetwork()) {
      throw const PlutoCloudSyncException(
        'No connection. Pluto will retry when you are back online.',
      );
    }

    if (kIsWeb) {
      throw const PlutoCloudSyncException(
        'Browser recordings are saved locally in this build. Cloud audio upload is available on mobile and desktop.',
      );
    }

    if (!await plutoAudioPathExists(note.localFilePath)) {
      throw const PlutoCloudSyncException(
        'This note cannot sync because its local audio file is missing.',
      );
    }

    try {
      final audioReference = storage.ref(
        'users/${note.userId}/audio_notes/${note.id}.m4a',
      );

      final uploadTask = await uploadPlutoAudioFile(
        audioReference: audioReference,
        audioPath: note.localFilePath,
        metadata: SettableMetadata(
          contentType: 'audio/mp4',
          customMetadata: {'noteId': note.id, 'userId': note.userId},
        ),
      );
      final cloudFileUrl = await uploadTask.ref.getDownloadURL();
      final syncedNote = note.markSynced(cloudFileUrl: cloudFileUrl);

      await _noteDocument(
        syncedNote.userId,
        syncedNote.id,
      ).set(_cloudNoteJson(syncedNote), SetOptions(merge: true));

      return syncedNote;
    } on FirebaseException catch (error) {
      throw PlutoCloudSyncException(_firebaseSyncMessage(error));
    }
  }

  Future<void> syncCategory(PlutoCategory category) async {
    _firestoreInstance();
    if (!await hasNetwork()) {
      throw const PlutoCloudSyncException(
        'No connection. Category changes will sync later.',
      );
    }

    try {
      await _categoryDocument(
        category.userId,
        category.id,
      ).set(category.toJson(), SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw PlutoCloudSyncException(_firebaseSyncMessage(error));
    }
  }

  Future<List<PlutoAudioNote>> pullRemoteNotes(String userId) async {
    final firestore = _firestoreInstance();
    if (!await hasNetwork()) {
      throw const PlutoCloudSyncException(
        'No connection. Showing notes saved on this device.',
      );
    }

    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .get();

      return snapshot.docs
          .map((document) => PlutoAudioNote.fromJson(document.data()))
          .toList();
    } on FirebaseException catch (error) {
      throw PlutoCloudSyncException(_firebaseSyncMessage(error));
    }
  }

  Future<List<PlutoCategory>> pullRemoteCategories(String userId) async {
    final firestore = _firestoreInstance();
    if (!await hasNetwork()) {
      throw const PlutoCloudSyncException(
        'No connection. Showing categories saved on this device.',
      );
    }

    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .get();

      return snapshot.docs
          .map((document) => PlutoCategory.fromJson(document.data()))
          .toList();
    } on FirebaseException catch (error) {
      throw PlutoCloudSyncException(_firebaseSyncMessage(error));
    }
  }

  Future<void> deleteCloudNote(PlutoAudioNote note) async {
    _firestoreInstance();
    if (!await hasNetwork()) {
      throw const PlutoCloudSyncException(
        'No connection. Pluto will delete this from cloud later.',
      );
    }

    try {
      await _noteDocument(
        note.userId,
        note.id,
      ).set(_cloudNoteJson(note.softDelete()), SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw PlutoCloudSyncException(_firebaseSyncMessage(error));
    }
  }

  Future<void> permanentlyDeleteCloudNote(PlutoAudioNote note) async {
    final storage = _storageInstance();
    if (!await hasNetwork()) {
      throw const PlutoCloudSyncException(
        'No connection. Permanent cloud deletion needs internet access.',
      );
    }

    try {
      await _noteDocument(note.userId, note.id).delete();
      final audioReference = storage.ref(
        'users/${note.userId}/audio_notes/${note.id}.m4a',
      );
      await audioReference.delete();
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found' || error.code == 'not-found') {
        return;
      }
      throw PlutoCloudSyncException(_firebaseSyncMessage(error));
    }
  }

  List<PlutoAudioNote> mergeRemoteNotes({
    required List<PlutoAudioNote> localNotes,
    required List<PlutoAudioNote> remoteNotes,
  }) {
    final notesById = <String, PlutoAudioNote>{
      for (final note in localNotes) note.id: note,
    };

    for (final remoteNote in remoteNotes) {
      final localNote = notesById[remoteNote.id];
      if (localNote == null) {
        notesById[remoteNote.id] = remoteNote;
        continue;
      }

      notesById[remoteNote.id] = _newestMetadataWins(
        localNote: localNote,
        remoteNote: remoteNote,
      );
    }

    final mergedNotes = notesById.values.toList();
    mergedNotes.sort(
      (left, right) => right.createdAt.compareTo(left.createdAt),
    );
    return mergedNotes;
  }

  List<PlutoCategory> mergeRemoteCategories({
    required List<PlutoCategory> localCategories,
    required List<PlutoCategory> remoteCategories,
  }) {
    final categoriesById = <String, PlutoCategory>{
      for (final category in localCategories) category.id: category,
    };

    for (final remoteCategory in remoteCategories) {
      final localCategory = categoriesById[remoteCategory.id];
      if (localCategory == null ||
          remoteCategory.updatedAt.isAfter(localCategory.updatedAt)) {
        categoriesById[remoteCategory.id] = remoteCategory;
      }
    }

    final mergedCategories = categoriesById.values.toList();
    mergedCategories.sort((left, right) => left.name.compareTo(right.name));
    return mergedCategories;
  }

  PlutoAudioNote _newestMetadataWins({
    required PlutoAudioNote localNote,
    required PlutoAudioNote remoteNote,
  }) {
    if (localNote.updatedAt.isAfter(remoteNote.updatedAt)) {
      return localNote;
    }

    return remoteNote.copyWith(
      localFilePath: localNote.localFilePath.isNotEmpty
          ? localNote.localFilePath
          : remoteNote.localFilePath,
      syncStatus: PlutoSyncStatus.synced,
    );
  }

  DocumentReference<Map<String, dynamic>> _noteDocument(
    String userId,
    String noteId,
  ) {
    return _firestoreInstance()
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(noteId);
  }

  DocumentReference<Map<String, dynamic>> _categoryDocument(
    String userId,
    String categoryId,
  ) {
    return _firestoreInstance()
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId);
  }

  FirebaseFirestore _firestoreInstance() {
    final firestore = _firestore;
    if (firestore == null) {
      throw const PlutoCloudSyncException('Cloud sync is not configured.');
    }
    return firestore;
  }

  FirebaseStorage _storageInstance() {
    final storage = _storage;
    if (storage == null) {
      throw const PlutoCloudSyncException('Cloud sync is not configured.');
    }
    return storage;
  }

  Map<String, Object?> _cloudNoteJson(PlutoAudioNote note) {
    final json = note.toJson();

    // local file paths are device-specific; cloud keeps the audio URL instead
    json['localFilePath'] = '';
    json['syncStatus'] = PlutoSyncStatus.synced.name;
    return json;
  }

  String _firebaseSyncMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
      case 'unauthorized':
        return 'Pluto could not sync because this account lacks access.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Sync service is unreachable. Pluto will retry later.';
      case 'quota-exceeded':
        return 'Cloud storage quota is full. Free space before syncing.';
      case 'object-not-found':
        return 'The cloud audio file is missing.';
      default:
        return 'Sync failed. ${error.message ?? 'Try again later.'}';
    }
  }
}

class PlutoCloudSyncException implements Exception {
  const PlutoCloudSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}
