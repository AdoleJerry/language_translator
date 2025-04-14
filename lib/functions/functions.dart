import 'dart:convert';
import 'package:final_year_project/audio_manager.dart';
import 'package:flutter_sound/flutter_sound.dart';
// import 'package:google_speech/google_speech.dart';

import 'package:http/http.dart' as http;

class GoogleTranslationService {
  final String apiKey;
  final AudioManager audioManager;
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  GoogleTranslationService(this.apiKey) : audioManager = AudioManager() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _player.openPlayer();
    await audioManager.initialize();
  }

  Future<String> translateText(
    String text,
    String targetLanguage,
  ) async {
    final String url =
        'https://translation.googleapis.com/language/translate/v2?key=$apiKey';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'q': text,
        'target': targetLanguage,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['translations'][0]['translatedText'];
    } else {
      throw Exception('Failed to translate text: ${response.body}');
    }
  }
  Future<void> dispose() async {
    await _player.closePlayer();
    await audioManager.dispose();
  }
}
