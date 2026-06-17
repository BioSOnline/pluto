import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<String> createPlutoRecordingPath(String id) async {
  final documentsDirectory = await getApplicationDocumentsDirectory();
  final recordingsDirectory = Directory(
    path.join(documentsDirectory.path, 'pluto_recordings'),
  );

  if (!recordingsDirectory.existsSync()) {
    await recordingsDirectory.create(recursive: true);
  }

  return path.join(recordingsDirectory.path, 'pluto-note-$id.m4a');
}

Future<bool> plutoAudioPathExists(String audioPath) async {
  return File(audioPath).exists();
}

Future<int> plutoAudioFileSizeBytes(String audioPath) async {
  return File(audioPath).length();
}

Future<void> deletePlutoAudioPath(String audioPath) async {
  final audioFile = File(audioPath);
  if (audioFile.existsSync()) {
    await audioFile.delete();
  }
}

Future<TaskSnapshot> uploadPlutoAudioFile({
  required Reference audioReference,
  required String audioPath,
  required SettableMetadata metadata,
}) {
  return audioReference.putFile(File(audioPath), metadata);
}
