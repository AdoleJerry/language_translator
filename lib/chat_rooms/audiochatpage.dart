import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart'; // Import file picker package
import 'package:final_year_project/custom_widgets/chatbubble.dart';
import 'package:final_year_project/functions/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:final_year_project/custom_widgets/supportedlanaguages.dart'; // Import the LanguageDropdown widget

class AudioChatPage extends StatefulWidget {
  const AudioChatPage({super.key});

  @override
  State<AudioChatPage> createState() => _AudioChatPageState();
}

class _AudioChatPageState extends State<AudioChatPage> {
  final List<Map<String, String>> _messages = []; // Stores user audio and translations
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final GoogleTranslationService _translationService =
      GoogleTranslationService('AIzaSyDc764MUCS1t8YulQ5RX686HEb3rq0WytM');
  final String _apiKey = "6514da3e3fca577263b6aba7966282483519b17e";
  late Deepgram _deepgram;
  String? _recordedFilePath;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _selectedLanguageCode; // Store the selected language code

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    await _recorder.openRecorder();
    await _player.openPlayer();
    _deepgram = Deepgram(_apiKey, baseQueryParams: {
      'model': 'nova-2-general',
      'detect_language': true,
      'punctuation': true,
    });
  }

  Future<void> _startRecording() async {
    final micStatus = await Permission.microphone.status;

    if (!micStatus.isGranted) {
      _showError("Permissions not granted. Please enable microphone and storage permissions.");
      return;
    }

    final directory = await getTemporaryDirectory();
    _recordedFilePath = '${directory.path}/audio.aac';

    await _recorder.startRecorder(
      toFile: _recordedFilePath,
      codec: Codec.aacADTS,
      sampleRate: 16000,
      numChannels: 1,
    );

    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();

    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _importAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _recordedFilePath = result.files.single.path;
      });
    } else {
      _showError("No audio file selected.");
    }
  }

  Future<void> _playRecording(String filePath) async {
    if (_isPlaying) {
      await _player.stopPlayer();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _player.startPlayer(
        fromURI: filePath,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
          });
        },
      );
      setState(() {
        _isPlaying = true;
      });
    }
  }

  Future<void> _transcribeAndTranslateAudio() async {
    if (_recordedFilePath == null) {
      _showError("No recording or imported audio found. Please record or import audio first.");
      return;
    }
    if (_selectedLanguageCode == null) {
      _showError("Please select a target language.");
      return;
    }
    try {
      final response = await _deepgram.listen.file(File(_recordedFilePath!));
      final transcription = response.transcript ?? "No transcription available.";

      final translatedText = await _translationService.translateText(transcription, _selectedLanguageCode!);

      setState(() {
        _messages.add({
          'audio': _recordedFilePath!,
          'translation': translatedText,
        });
      });
    } catch (e) {
      _showError("Error during transcription or translation: $e");
    }
  }
Future<void> _playAudio(String filePath) async {
  if (_isPlaying) {
    await _player.stopPlayer();
    setState(() {
      _isPlaying = false;
    });
  } else {
    await _player.startPlayer(
      fromURI: filePath,
      codec: Codec.aacADTS,
      whenFinished: () {
        setState(() {
          _isPlaying = false;
        });
      },
    );
    setState(() {
      _isPlaying = true;
    });
  }
}
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Audio Translation"),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 25),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight, // User's audio on the right
                      child: ElevatedButton.icon(
                        onPressed: () => _playRecording(message['audio']!),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("Play Audio"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[100],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft, // Translation on the left
                      child: ChatBubble(
                        text: message['translation']!,
                        color: Colors.green[100]!,
                        isUser: false,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                LanguageDropdown(
                  onLanguageSelected: (String selectedLanguageCode) {
                    setState(() {
                      _selectedLanguageCode = selectedLanguageCode;
                    });
                  },
                  fillColor: Colors.white,
                ),
                const SizedBox(height: 10),
                Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    // Start/Stop Recording Button
    ElevatedButton.icon(
      onPressed: _isPlaying
          ? null // Disable recording while playing audio
          : (_isRecording ? _stopRecording : _startRecording),
      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
      label: Text(_isRecording ? "Stop Recording" : "Start Recording"),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isRecording ? Colors.red : Colors.blue,
      ),
    ),
    const SizedBox(width: 10),
    // Play/Stop Audio Button
    ElevatedButton.icon(
      onPressed: _isRecording || _recordedFilePath == null
          ? null // Disable playing while recording or if no audio is available
          : () async {
              await _playAudio(_recordedFilePath!); // Play or stop the audio
            },
      icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow), // Switch icon
      label: Text(_isPlaying ? "Stop" : "Play"),
      style: ElevatedButton.styleFrom(
        backgroundColor: _recordedFilePath != null
            ? (_isPlaying ? Colors.red : Colors.orange)
            : Colors.grey,
      ),
    ),
    const SizedBox(width: 10),
    // Send Audio Button
    IconButton(
  onPressed: _recordedFilePath != null && !_isRecording && !_isPlaying
      ? _transcribeAndTranslateAudio
      : null, // Disable sending while recording or playing
  icon: const Icon(Icons.send, color: Colors.green),
  tooltip: 'Send Audio', // Tooltip for accessibility
  color: _recordedFilePath != null && !_isRecording && !_isPlaying
      ? Colors.green
      : Colors.grey, // Change color dynamically
),
   
  ],
),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                          onPressed: _importAudio,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          icon: const Icon(Icons.attach_file),
                          label: const Text("Import Audio"),
                        ),
                        const SizedBox(width: 10), 
                        
                     ElevatedButton.icon(
                      onPressed: _recordedFilePath != null ? () {
                     setState(() {
                    _recordedFilePath = null; // Clear the recorded file path
                    },
                    );
                                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Recording deleted.")),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.delete),
                          label: const Text("Delete"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _recordedFilePath != null ? Colors.red : Colors.grey,
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}