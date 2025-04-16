import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart'; // Import file picker package
import 'package:final_year_project/custom_widgets/chatbubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_year_project/functions/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:final_year_project/custom_widgets/supportedlanaguages.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import the LanguageDropdown widget

class AudioChatPage extends StatefulWidget {
  final String? userUid;
  const AudioChatPage({super.key, this.userUid});

  @override
  State<AudioChatPage> createState() => _AudioChatPageState();
}

class _AudioChatPageState extends State<AudioChatPage> {

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final ScrollController _scrollController = ScrollController(); // Add ScrollController
  final GoogleTranslationService _translationService =
      GoogleTranslationService('AIzaSyDc764MUCS1t8YulQ5RX686HEb3rq0WytM');
  final String _apiKey = "6514da3e3fca577263b6aba7966282483519b17e";
  late Deepgram _deepgram;
  String? _recordedFilePath;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isSending = false; // Track if a message is being sent
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
      // Transcribe the audio
      final response = await _deepgram.listen.file(File(_recordedFilePath!));
      final transcription = response.transcript ?? "No transcription available.";

      // Translate the transcription
      final translatedText = await _translationService.translateText(transcription, _selectedLanguageCode!);

      // Upload the audio file to Firebase Storage and get the download URL
      final audioUrl = await _uploadAudioToStorage();

      // Add the transcription, translation, and audio URL to Firestore
      await _uploadToFirestore(transcription, translatedText, audioUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Audio transcription, translation, and audio uploaded successfully.")),
      );
    } catch (e) {
      _showError("Error during transcription or translation: $e");
    }
  }

  Future<String> _uploadAudioToStorage() async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final audioRef = storageRef.child('audio_files/${DateTime.now().millisecondsSinceEpoch}.aac');

      // Upload the audio file
      // ignore: unused_local_variable
      final uploadTask = await audioRef.putFile(File(_recordedFilePath!));

      // Get the download URL after the file is uploaded
      final downloadUrl = await audioRef.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      _showError("Error uploading audio to Firebase Storage: $e");
      rethrow;
    }
  }

  Future<void> _uploadToFirestore(String transcription, String translation, String audioUrl) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Create a document in the "audio_translations" collection
      await firestore.collection('audio_translations').doc(widget.userUid).collection('messages').add({
        'transcription': transcription,
        'translation': translation,
        'audioUrl': audioUrl, // Add the audio URL
        'timestamp': FieldValue.serverTimestamp(), // Add a timestamp
      });

    } catch (e) {
      _showError("Error sending message");
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

  Future<void> _deleteMessage(String documentId, String? audioUrl) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Delete the audio file from Firebase Storage if audioUrl exists
      if (audioUrl != null) {
        final storageRef = FirebaseStorage.instance.refFromURL(audioUrl);
        await storageRef.delete();
        print("Audio file deleted from Firebase Storage.");
      }

      // Delete the Firestore document
      await firestore
          .collection('audio_translations')
          .doc(widget.userUid)
          .collection('messages')
          .doc(documentId)
          .delete();
      print("Message deleted from Firestore.");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Message deleted successfully.")),
      );
    } catch (e) {
      _showError("Error deleting message: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    _scrollController.dispose(); // Dispose of the ScrollController
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('audio_translations')
                  .doc(widget.userUid) // Use the user's UID to fetch their messages
                  .collection('messages')
                  .orderBy('timestamp', descending: false) // Order by timestamp
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages found."));
                }

                final messages = snapshot.data!.docs;

                // Scroll to the bottom when new messages are loaded
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController, // Attach the ScrollController
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final transcription = message['transcription']?.isNotEmpty == true
                        ? message['transcription']
                        : "Error understanding audio, can you say it again?";
                    final translation = message['translation']?.isNotEmpty == true
                        ? message['translation']
                        : "Error understanding audio, can you say it again?";
                    final data = message.data() as Map<String, dynamic>;
                    final audioUrl = data.containsKey('audioUrl') ? data['audioUrl'] : null; // Check if audioUrl exists
                    final timestamp =  message['timestamp'] as Timestamp?; // Get the timestamp
                    final formattedDate = timestamp != null
                        ? DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate())
                        : 'Unknown Date';
                    // Get the document ID

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (audioUrl != null) // Only show the play button if audioUrl exists
                          Align(
                            alignment: Alignment.centerRight, // User's audio on the right
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _player.startPlayer(
                                  fromURI: audioUrl,
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
                              },
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
                            text: translation,
                            color: Colors.green[100]!,
                            isUser: false,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft, // Transcription on the left
                          child: ChatBubble(
                            text: transcription,
                            color: Colors.grey[200]!,
                            isUser: false,
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        
                      ],
                    );
                  },
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
                    IconButton(
                      onPressed: _recordedFilePath != null && !_isRecording && !_isPlaying && !_isSending
                          ? () async {
                              setState(() {
                                _isSending = true; // Start sending
                              });

                              try {
                                await _transcribeAndTranslateAudio(); // Send the message
                              } finally {
                                setState(() {
                                  _isSending = false; // Reset after sending
                                });
                              }
                            }
                          : null, // Disable button if conditions are not met
                      icon: _isSending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.green,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.green),
                      tooltip: 'Send Audio', // Tooltip for accessibility
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      onPressed: _recordedFilePath != null
                          ? () {
                              setState(() {
                                _recordedFilePath = null; // Clear the recorded file path
                              });
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