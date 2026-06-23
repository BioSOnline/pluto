import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import 'pluto_audio_file.dart';

class PlutoAudioService {
  PlutoAudioService({AudioRecorder? recorder, AudioPlayer? player, Uuid? uuid})
    : _recorder = recorder ?? AudioRecorder(),
      _player = player ?? AudioPlayer(),
      _uuid = uuid ?? const Uuid();

  final AudioRecorder _recorder;
  final AudioPlayer _player;
  final Uuid _uuid;

  Stream<RecordState> get recordingState => _recorder.onStateChanged();

  Stream<Duration> get playbackPosition => _player.positionStream;

  Stream<Duration?> get playbackDuration => _player.durationStream;

  Stream<PlayerState> get playbackState => _player.playerStateStream;

  String? get playingNotePath => _loadedPlaybackPath;

  DateTime? _recordingStartedAt;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pauseStartedAt;
  String? _activeRecordingPath;
  String? _loadedPlaybackPath;

  Future<bool> hasMicrophonePermission() async {
    return (await _recorder.hasPermission()) == true;
  }

  /// Requests microphone access from the OS.
  /// Returns `true` if the permission was granted.
  Future<bool> requestMicrophonePermission() async {
    if (kIsWeb) {
      // Web uses the browser permission dialog triggered by the recorder itself.
      return (await _recorder.hasPermission()) == true;
    }
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<PlutoRecordingSession> startRecording() async {
    final hasPermission = (await _recorder.hasPermission()) == true;
    if (!hasPermission) {
      throw const PlutoAudioException(
        'Microphone permission is required to record a voice note.',
      );
    }

    final recordingPath = await createPlutoRecordingPath(_uuid.v4());
    final encoder = kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc;

    final config = RecordConfig(
      encoder: encoder,
      bitRate: 128000,
      sampleRate: 44100,
      numChannels: kIsWeb ? 1 : 2,
    );

    try {
      await _recorder.start(config, path: recordingPath);
    } catch (_) {
      // Graceful fallback for web environments with limited hardware constraints
      await _recorder.start(
        RecordConfig(encoder: encoder, bitRate: 192000, sampleRate: 48000),
        path: recordingPath,
      );
    }

    _recordingStartedAt = DateTime.now();
    _pausedDuration = Duration.zero;
    _pauseStartedAt = null;
    _activeRecordingPath = recordingPath;

    return PlutoRecordingSession(
      filePath: recordingPath,
      startedAt: _recordingStartedAt!,
    );
  }

  Future<void> pauseRecording() async {
    final isRecording = await _recorder.isRecording();
    if (!isRecording) {
      return;
    }

    await _recorder.pause();
    _pauseStartedAt = DateTime.now();
  }

  Future<void> resumeRecording() async {
    final isPaused = await _recorder.isPaused();
    if (!isPaused) {
      return;
    }

    final pauseStartedAt = _pauseStartedAt;
    if (pauseStartedAt != null) {
      _pausedDuration += DateTime.now().difference(pauseStartedAt);
    }

    await _recorder.resume();
    _pauseStartedAt = null;
  }

  Future<PlutoFinishedRecording> stopRecording() async {
    final activeRecordingPath = _activeRecordingPath;
    if (activeRecordingPath == null) {
      throw const PlutoAudioException('There is no active recording to save.');
    }

    final stoppedPath = await _recorder.stop();
    final savedPath = stoppedPath ?? activeRecordingPath;

    if (!await plutoAudioPathExists(savedPath)) {
      throw const PlutoAudioException('The recording file could not be found.');
    }

    final fileSizeBytes = await plutoAudioFileSizeBytes(savedPath);
    final duration = await _readRecordedDuration(savedPath);

    _recordingStartedAt = null;
    _pausedDuration = Duration.zero;
    _pauseStartedAt = null;
    _activeRecordingPath = null;

    return PlutoFinishedRecording(
      filePath: savedPath,
      duration: duration,
      fileSizeBytes: fileSizeBytes,
    );
  }

  Future<void> cancelRecording() async {
    final activeRecordingPath = _activeRecordingPath;
    await _recorder.cancel();

    if (activeRecordingPath != null) {
      await deletePlutoAudioPath(activeRecordingPath);
    }

    _recordingStartedAt = null;
    _pausedDuration = Duration.zero;
    _pauseStartedAt = null;
    _activeRecordingPath = null;
  }

  Duration currentRecordingDuration() {
    final recordingStartedAt = _recordingStartedAt;
    if (recordingStartedAt == null) {
      return Duration.zero;
    }

    final now = DateTime.now();
    final activePause = _pauseStartedAt == null
        ? Duration.zero
        : now.difference(_pauseStartedAt!);

    return now.difference(recordingStartedAt) - _pausedDuration - activePause;
  }

  Future<void> loadPlayback(String audioPath) async {
    if (!await plutoAudioPathExists(audioPath)) {
      throw const PlutoAudioException('This audio file is missing locally.');
    }

    if (_loadedPlaybackPath == audioPath) {
      return;
    }

    await _player.stop();
    if (kIsWeb) {
      await _player.setUrl(audioPath);
    } else {
      await _player.setFilePath(audioPath);
    }
    _loadedPlaybackPath = audioPath;
  }

  Future<void> play(String audioPath) async {
    if (_loadedPlaybackPath == audioPath) {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
      return;
    }
    await loadPlayback(audioPath);
    await _player.play();
  }

  Future<void> pausePlayback() async {
    await _player.pause();
  }

  Future<void> seekPlayback(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  Future<void> stopPlayback() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
  }

  Future<Duration> _readRecordedDuration(String audioPath) async {
    if (kIsWeb) {
      return currentRecordingDuration();
    }

    final probePlayer = AudioPlayer();
    try {
      final duration = await probePlayer.setFilePath(audioPath);

      // record does not hand back duration, so just_audio probes the saved file
      return duration ?? currentRecordingDuration();
    } on PlayerException {
      return currentRecordingDuration();
    } finally {
      await probePlayer.dispose();
    }
  }
}

class PlutoRecordingSession {
  const PlutoRecordingSession({
    required this.filePath,
    required this.startedAt,
  });

  final String filePath;
  final DateTime startedAt;
}

class PlutoFinishedRecording {
  const PlutoFinishedRecording({
    required this.filePath,
    required this.duration,
    required this.fileSizeBytes,
  });

  final String filePath;
  final Duration duration;
  final int fileSizeBytes;
}

class PlutoAudioException implements Exception {
  const PlutoAudioException(this.message);

  final String message;

  @override
  String toString() => message;
}
