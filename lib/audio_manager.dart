import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

class AudioManager {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlaying = false;
  String? _currentAudioPath;

  Future<void> initialize() async {
    await _player.openPlayer();
  }

  Future<String> saveAudio(List<int> audioData,
      {String? customFileName}) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        customFileName ?? 'audio_${DateTime.now().millisecondsSinceEpoch}.wav';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(audioData);
    _currentAudioPath = filePath;
    return filePath;
  }

  Future<void> playAudio(String audioPath) async {
    if (_isPlaying) {
      await stopPlaying();
    }

    try {
      await _player.startPlayer(
        fromURI: audioPath,
        codec: Codec.pcm16WAV,
        whenFinished: () {
          _isPlaying = false;
        },
      );
      _isPlaying = true;
      _currentAudioPath = audioPath;
    } catch (e) {
      if (kDebugMode) {
        print('Error playing audio: $e');
      }
    }
  }

  Future<void> stopPlaying() async {
    try {
      await _player.stopPlayer();
      _isPlaying = false;
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping playback: $e');
      }
    }
  }

  Future<void> dispose() async {
    await stopPlaying();
    await _player.closePlayer();
  }

  bool get isPlaying => _isPlaying;
  String? get currentAudioPath => _currentAudioPath;
}
