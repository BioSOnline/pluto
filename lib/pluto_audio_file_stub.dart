import 'package:firebase_storage/firebase_storage.dart';

Future<String> createPlutoRecordingPath(String id) async {
  return 'pluto-note-$id.m4a';
}

Future<bool> plutoAudioPathExists(String audioPath) async {
  return audioPath.isNotEmpty;
}

Future<int> plutoAudioFileSizeBytes(String audioPath) async {
  return 0;
}

Future<void> deletePlutoAudioPath(String audioPath) async {}

Future<TaskSnapshot> uploadPlutoAudioFile({
  required Reference audioReference,
  required String audioPath,
  required SettableMetadata metadata,
}) {
  throw UnsupportedError('File upload is not available on this platform.');
}
