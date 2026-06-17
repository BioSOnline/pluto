import 'package:firebase_storage/firebase_storage.dart';

Future<String> createPlutoRecordingPath(String id) async {
  return '';
}

Future<bool> plutoAudioPathExists(String audioPath) async {
  return audioPath.startsWith('blob:') || audioPath.isNotEmpty;
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
  throw UnsupportedError('Browser blob upload is not available in this build.');
}
