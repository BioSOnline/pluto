import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pluto_app_controller.dart';
import 'pluto_audio_service.dart';
import 'pluto_auth_service.dart';
import 'pluto_cloud_sync_service.dart';
import 'pluto_local_store.dart';
import 'pluto_note_repository.dart';

/// Set to `true` in widget tests to disable Firebase and audio services.
final plutoIsTestProvider = Provider<bool>((ref) => false);

final plutoLocalStoreProvider = Provider<PlutoLocalStore>((ref) {
  final localStore = PlutoLocalStore();
  ref.onDispose(() => unawaited(localStore.dispose()));
  return localStore;
});

final plutoAuthServiceProvider = Provider<PlutoAuthService>((ref) {
  if (ref.watch(plutoIsTestProvider)) {
    return PlutoAuthService.test();
  }
  return PlutoAuthService();
});

final plutoAudioServiceProvider = Provider<PlutoAudioService>((ref) {
  return PlutoAudioService();
});

final plutoCloudSyncServiceProvider = Provider<PlutoCloudSyncService>((ref) {
  if (ref.watch(plutoIsTestProvider)) {
    return PlutoCloudSyncService.test();
  }
  return PlutoCloudSyncService();
});

final plutoNoteRepositoryProvider = Provider<PlutoNoteRepository>((ref) {
  return PlutoNoteRepository(
    localStore: ref.watch(plutoLocalStoreProvider),
    cloudSyncService: ref.watch(plutoCloudSyncServiceProvider),
  );
});

/// The main app controller, now using the idiomatic Riverpod v3 [NotifierProvider].
/// Widgets should watch this provider and access state via the notifier's
/// convenience getters (e.g. `controller.visibleNotes`) or directly via
/// `ref.watch(plutoAppControllerProvider).visibleNotes`.
final plutoAppControllerProvider =
    NotifierProvider<PlutoAppController, PlutoAppState>(
  PlutoAppController.new,
);
