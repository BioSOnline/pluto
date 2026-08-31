import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

import 'pluto_audio_service.dart';
import 'pluto_auth_service.dart';
import 'pluto_local_store.dart';
import 'pluto_note.dart';
import 'pluto_note_repository.dart';
// providers is imported here so the Notifier can read sibling providers via ref.
// The pluto_providers.dart file imports this file back, which is safe in Dart
// because the dependency is only on the provider identifiers, not on types.
import 'pluto_providers.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class PlutoAppState {
  const PlutoAppState({
    this.activeUser,
    this.allNotes = const [],
    this.visibleNotes = const [],
    this.trashNotes = const [],
    this.categories = const [],
    this.activeFilter = const PlutoNoteFilter(),
    this.recordingState = PlutoRecordingState.idle,
    this.playback = const PlutoPlaybackSnapshot(),
    this.recordingDuration = Duration.zero,
    this.isBusy = false,
    this.isSyncing = false,
    this.currentErrorMessage,
  });

  final PlutoUser? activeUser;
  final List<PlutoAudioNote> allNotes;
  final List<PlutoAudioNote> visibleNotes;
  final List<PlutoAudioNote> trashNotes;
  final List<PlutoCategory> categories;
  final PlutoNoteFilter activeFilter;
  final PlutoRecordingState recordingState;
  final PlutoPlaybackSnapshot playback;
  final Duration recordingDuration;
  final bool isBusy;
  final bool isSyncing;
  final String? currentErrorMessage;

  PlutoAppState copyWith({
    PlutoUser? activeUser,
    bool clearActiveUser = false,
    List<PlutoAudioNote>? allNotes,
    List<PlutoAudioNote>? visibleNotes,
    List<PlutoAudioNote>? trashNotes,
    List<PlutoCategory>? categories,
    PlutoNoteFilter? activeFilter,
    PlutoRecordingState? recordingState,
    PlutoPlaybackSnapshot? playback,
    Duration? recordingDuration,
    bool? isBusy,
    bool? isSyncing,
    String? currentErrorMessage,
    bool clearError = false,
  }) {
    return PlutoAppState(
      activeUser:
          clearActiveUser ? null : activeUser ?? this.activeUser,
      allNotes: allNotes ?? this.allNotes,
      visibleNotes: visibleNotes ?? this.visibleNotes,
      trashNotes: trashNotes ?? this.trashNotes,
      categories: categories ?? this.categories,
      activeFilter: activeFilter ?? this.activeFilter,
      recordingState: recordingState ?? this.recordingState,
      playback: playback ?? this.playback,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      isBusy: isBusy ?? this.isBusy,
      isSyncing: isSyncing ?? this.isSyncing,
      currentErrorMessage:
          clearError ? null : currentErrorMessage ?? this.currentErrorMessage,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class PlutoAppController extends Notifier<PlutoAppState> {
  late final PlutoAuthService _authService;
  late final PlutoAudioService _audioService;
  late final PlutoLocalStore _localStore;
  late final PlutoNoteRepository _noteRepository;

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _recordingTimer;

  @override
  PlutoAppState build() {
    _authService = ref.read(plutoAuthServiceProvider);
    _audioService = ref.read(plutoAudioServiceProvider);
    _localStore = ref.read(plutoLocalStoreProvider);
    _noteRepository = ref.read(plutoNoteRepositoryProvider);

    ref.onDispose(() {
      _recordingTimer?.cancel();
      for (final sub in _subscriptions) {
        sub.cancel();
      }
      unawaited(_audioService.dispose());
    });

    // Boot asynchronously so the app shell renders immediately.
    if (!ref.read(plutoIsTestProvider)) {
      unawaited(_initialize());
    }

    return const PlutoAppState();
  }

  // ─── Init ──────────────────────────────────────────────────────────────────

  Future<void> _initialize() async {
    await _localStore.initialize();

    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      await _activateUser(currentUser);
    } else {
      await _noteRepository.initializeForUser(_localStore.activeUserId);
      _reloadNotes();
    }

    _subscriptions.add(
      _authService.authStateChanges.listen((user) async {
        if (user == null) {
          await _localStore.clearLocalSession();
          await _noteRepository.initializeForUser(_localStore.activeUserId);
          state = state.copyWith(clearActiveUser: true);
        } else {
          await _activateUser(user);
        }
        _reloadNotes();
      }),
    );
    _subscriptions.add(
      _noteRepository.changes.listen((_) => _reloadNotes()),
    );
    _subscriptions.add(
      _audioService.recordingState.listen(_handleRecorderState),
    );
    _subscriptions.add(
      _audioService.playbackPosition.listen((position) {
        state = state.copyWith(
          playback: state.playback.copyWith(position: position),
        );
      }),
    );
    _subscriptions.add(
      _audioService.playbackDuration.listen((duration) {
        state = state.copyWith(
          playback: state.playback.copyWith(
            duration: duration ?? Duration.zero,
          ),
        );
      }),
    );
    _subscriptions.add(
      _audioService.playbackState.listen(_handlePlaybackState),
    );
    _subscriptions.add(
      _noteRepository.connectivityChanges.listen((results) {
        if (_hasNetwork(results)) {
          unawaited(_syncInBackground());
        }
      }),
    );
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────

  Future<void> signInWithEmail(String email, String password) async {
    await _runBusyAction(() async {
      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      await _activateUser(user);
    });
  }

  Future<void> createAccountWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    await _runBusyAction(() async {
      final user = await _authService.createAccountWithEmail(
        displayName: displayName,
        email: email,
        password: password,
      );
      await _activateUser(user);
    });
  }

  Future<void> signInWithGoogle() async {
    await _runBusyAction(() async {
      final user = await _authService.signInWithGoogle();
      await _activateUser(user);
    });
  }

  Future<void> signInWithApple() async {
    await _runBusyAction(() async {
      final user = await _authService.signInWithApple();
      await _activateUser(user);
    });
  }

  Future<void> signOut() async {
    await _runBusyAction(() async {
      await _audioService.stopPlayback();
      await _authService.signOut();
      await _localStore.clearLocalSession();
      await _noteRepository.initializeForUser(_localStore.activeUserId);
      state = state.copyWith(clearActiveUser: true);
      _reloadNotes();
    });
  }

  // ─── Recording ─────────────────────────────────────────────────────────────

  Future<void> startRecording() async {
    await _runBusyAction(() async {
      await _audioService.startRecording();
      state = state.copyWith(
        recordingState: PlutoRecordingState.recording,
        recordingDuration: Duration.zero,
      );
      _startRecordingTimer();
    });
  }

  Future<void> pauseRecording() async {
    await _runBusyAction(() async {
      await _audioService.pauseRecording();
      _recordingTimer?.cancel();
      state = state.copyWith(recordingState: PlutoRecordingState.paused);
    });
  }

  Future<void> resumeRecording() async {
    await _runBusyAction(() async {
      await _audioService.resumeRecording();
      state = state.copyWith(
        recordingState: PlutoRecordingState.recording,
      );
      _startRecordingTimer();
    });
  }

  Future<PlutoAudioNote?> stopAndSaveRecording({
    required String title,
    required List<String> tags,
  }) async {
    PlutoAudioNote? savedNote;
    await _runBusyAction(() async {
      _recordingTimer?.cancel();
      state = state.copyWith(
        recordingState: PlutoRecordingState.saving,
        recordingDuration: Duration.zero,
      );

      final finishedRecording = await _audioService.stopRecording();
      savedNote = await _noteRepository.saveFinishedRecording(
        recording: finishedRecording,
        requestedTitle: title,
        requestedTags: tags,
        // Transcription is not yet implemented; pass null to omit the field.
        transcript: null,
      );

      state = state.copyWith(
        recordingDuration: Duration.zero,
        recordingState: PlutoRecordingState.idle,
      );
      _reloadNotes();
    });
    return savedNote;
  }

  Future<void> cancelRecording() async {
    await _runBusyAction(() async {
      await _audioService.cancelRecording();
      _recordingTimer?.cancel();
      state = state.copyWith(
        recordingDuration: Duration.zero,
        recordingState: PlutoRecordingState.idle,
      );
    });
  }

  // ─── Playback ──────────────────────────────────────────────────────────────

  Future<void> togglePlayback(PlutoAudioNote note) async {
    if (state.playback.noteId == note.id && state.playback.isPlaying) {
      await pausePlayback();
    } else {
      await playNote(note);
    }
  }

  Future<void> playNote(PlutoAudioNote note) async {
    // Instant optimistic state: the play button responds in 0ms!
    final isSwitchingNote = state.playback.noteId != note.id;
    state = state.copyWith(
      playback: state.playback.copyWith(
        noteId: note.id,
        isPlaying: true,
        isLoading: isSwitchingNote,
      ),
    );

    try {
      await _audioService.play(note.localFilePath);
    } catch (error) {
      state = state.copyWith(
        playback: state.playback.copyWith(
          isPlaying: false,
          isLoading: false,
        ),
        currentErrorMessage: 'Could not play audio: ${error.toString()}',
      );
    }
  }

  Future<void> pausePlayback() async {
    // Instant optimistic pause response
    state = state.copyWith(
      playback: state.playback.copyWith(
        isPlaying: false,
        isLoading: false,
      ),
    );
    try {
      await _audioService.pausePlayback();
    } catch (_) {}
  }

  Future<void> seekPlayback(Duration position) async {
    state = state.copyWith(
      playback: state.playback.copyWith(position: position),
    );
    try {
      await _audioService.seekPlayback(position);
    } catch (_) {}
  }

  Future<void> setPlaybackSpeed(double speed) async {
    state = state.copyWith(
      playback: state.playback.copyWith(speed: speed),
    );
    try {
      await _audioService.setSpeed(speed);
    } catch (_) {}
  }

  // ─── Notes ─────────────────────────────────────────────────────────────────

  Future<void> renameNote(String noteId, String nextTitle) async {
    await _runBusyAction(() async {
      await _noteRepository.renameNote(noteId, nextTitle);
      _reloadNotes();
    });
  }

  Future<void> moveNoteToCategory(
    String noteId,
    String categoryId,
  ) async {
    await _runBusyAction(() async {
      await _noteRepository.moveNoteToCategory(noteId, categoryId);
      _reloadNotes();
    });
  }

  Future<void> updateNoteTags(
    String noteId,
    List<String> tags,
  ) async {
    await _runBusyAction(() async {
      await _noteRepository.updateNoteTags(noteId, tags);
      _reloadNotes();
    });
  }

  Future<void> toggleFavorite(String noteId) async {
    await _runBusyAction(() async {
      await _noteRepository.toggleFavorite(noteId);
      _reloadNotes();
    });
  }

  Future<void> deleteNote(String noteId) async {
    await _runBusyAction(() async {
      await _noteRepository.deleteNote(noteId);
      _reloadNotes();
    });
  }

  Future<void> restoreNote(String noteId) async {
    await _runBusyAction(() async {
      await _noteRepository.restoreNote(noteId);
      _reloadNotes();
    });
  }

  Future<void> permanentlyDeleteNote(String noteId) async {
    await _runBusyAction(() async {
      await _noteRepository.permanentlyDeleteNote(noteId);
      _reloadNotes();
    });
  }

  // ─── Categories ────────────────────────────────────────────────────────────

  Future<void> createCategory({
    required String name,
    required int colorValue,
  }) async {
    await _runBusyAction(() async {
      await _noteRepository.createCategory(
        name: name,
        colorValue: colorValue,
      );
      _reloadNotes();
    });
  }

  Future<void> renameCategory(String categoryId, String nextName) async {
    await _runBusyAction(() async {
      await _noteRepository.renameCategory(categoryId, nextName);
      _reloadNotes();
    });
  }

  // ─── Sync ──────────────────────────────────────────────────────────────────

  Future<void> retryFailedSync() async {
    await _runSyncAction(() async {
      await _noteRepository.retryFailedSync();
      _reloadNotes();
    });
  }

  Future<void> refreshCloudNotes() async {
    final user = state.activeUser;
    if (user == null) return;

    await _runSyncAction(() async {
      await _noteRepository.refreshFromCloud(user.id);
      await _noteRepository.syncPendingNotes();
      _reloadNotes();
    });
  }

  // ─── Filters ───────────────────────────────────────────────────────────────

  void updateFilter(PlutoNoteFilter filter) {
    state = state.copyWith(activeFilter: filter);
    _reloadNotes();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // ─── Read helpers ──────────────────────────────────────────────────────────

  PlutoCategory? categoryFor(String categoryId) {
    for (final category in state.categories) {
      if (category.id == categoryId) return category;
    }
    return null;
  }

  // ─── Getters that mirror old ChangeNotifier public fields ─────────────────
  // These convenience getters let existing widget code use `controller.xxx`
  // without requiring every call site to be updated to `controller.state.xxx`.

  PlutoUser? get activeUser => state.activeUser;
  List<PlutoAudioNote> get allNotes => state.allNotes;
  List<PlutoAudioNote> get visibleNotes => state.visibleNotes;
  List<PlutoAudioNote> get trashNotes => state.trashNotes;
  List<PlutoCategory> get categories => state.categories;
  PlutoNoteFilter get activeFilter => state.activeFilter;
  PlutoRecordingState get recordingState => state.recordingState;
  PlutoPlaybackSnapshot get playback => state.playback;
  Duration get recordingDuration => state.recordingDuration;
  bool get isBusy => state.isBusy;
  bool get isSyncing => state.isSyncing;
  String? get currentErrorMessage => state.currentErrorMessage;

  // ─── Private helpers ───────────────────────────────────────────────────────

  Future<void> _activateUser(PlutoUser user) async {
    state = state.copyWith(activeUser: user);
    await _noteRepository.initializeForUser(user.id);
    await refreshCloudNotes();
  }

  void _reloadNotes() {
    state = state.copyWith(
      allNotes: _noteRepository.loadVisibleNotes(),
      categories: _noteRepository.loadCategories(),
      visibleNotes: _noteRepository.searchNotes(state.activeFilter),
      trashNotes: _noteRepository.loadTrash(),
    );
  }

  Future<void> _syncInBackground() async {
    if (state.isSyncing || state.activeUser == null) return;

    await _runSyncAction(() async {
      await _noteRepository.syncPendingNotes();
      _reloadNotes();
    });
  }

  Future<void> _runBusyAction(Future<void> Function() action) async {
    state = state.copyWith(isBusy: true, clearError: true);

    try {
      await action();
    } on PlutoAuthException catch (error) {
      state = state.copyWith(currentErrorMessage: error.message);
    } on PlutoAudioException catch (error) {
      state = state.copyWith(
        currentErrorMessage: error.message,
        recordingState: PlutoRecordingState.idle,
      );
    } on PlutoLocalStoreException catch (error) {
      state = state.copyWith(currentErrorMessage: error.message);
    } on PlutoNoteRepositoryException catch (error) {
      state = state.copyWith(currentErrorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        currentErrorMessage:
            'Something went wrong. Pluto kept your local data.',
      );
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<void> _runSyncAction(Future<void> Function() action) async {
    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      await action();
    } catch (_) {
      state = state.copyWith(
        currentErrorMessage:
            'Sync failed. Your local notes are still safe.',
      );
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  void _handleRecorderState(RecordState recordState) {
    switch (recordState) {
      case RecordState.record:
        state = state.copyWith(
          recordingState: PlutoRecordingState.recording,
        );
        break;
      case RecordState.pause:
        state = state.copyWith(
          recordingState: PlutoRecordingState.paused,
        );
        break;
      case RecordState.stop:
        if (state.recordingState != PlutoRecordingState.saving) {
          state = state.copyWith(
            recordingState: PlutoRecordingState.idle,
          );
        }
        break;
    }
  }

  void _handlePlaybackState(PlayerState playerState) {
    final isCompleted =
        playerState.processingState == ProcessingState.completed;
    final isBuffering =
        playerState.processingState == ProcessingState.buffering ||
        playerState.processingState == ProcessingState.loading;

    state = state.copyWith(
      playback: state.playback.copyWith(
        isPlaying: playerState.playing && !isCompleted,
        isLoading: isBuffering,
        position: isCompleted ? Duration.zero : null,
      ),
    );
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) {
        state = state.copyWith(
          recordingDuration: _audioService.currentRecordingDuration(),
        );
      },
    );
  }

  bool _hasNetwork(List<ConnectivityResult> results) {
    return results.any(
      (result) => result != ConnectivityResult.none,
    );
  }
}

// ─── Supporting Enums & Value Objects ────────────────────────────────────────

enum PlutoRecordingState { idle, recording, paused, saving }

class PlutoPlaybackSnapshot {
  const PlutoPlaybackSnapshot({
    this.noteId,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.isLoading = false,
    this.speed = 1.0,
  });

  final String? noteId;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isLoading;
  final double speed;

  PlutoPlaybackSnapshot copyWith({
    String? noteId,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? isLoading,
    double? speed,
  }) {
    return PlutoPlaybackSnapshot(
      noteId: noteId ?? this.noteId,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      speed: speed ?? this.speed,
    );
  }
}
