import 'package:final_year_project/chat_rooms/audio_chat_function.dart';
import 'package:final_year_project/custom_widgets/chatbubble.dart';
import 'package:final_year_project/custom_widgets/supportedlanaguages.dart';
import 'package:flutter/material.dart';
import '../functions/functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TextChatbox extends StatefulWidget {
  final String? userUid; // Optional parameter to pass user UID
  
  const TextChatbox({super.key, this.userUid});

  @override
  TextChatboxState createState() => TextChatboxState();
}

class TextChatboxState extends State<TextChatbox> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Add ScrollController
  final List<Map<String, String>> _messages = [];
  String? _selectedLanguage;
  bool _isTranslating = false;
  final GoogleTranslationService _translationService;

  TextChatboxState()
      : _translationService =
            GoogleTranslationService('AIzaSyDc764MUCS1t8YulQ5RX686HEb3rq0WytM');

  Future<void> _translateText(String userUid) async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter text to translate.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a target language.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    try {
      final translation = await _translationService.translateText(
        text,
        _selectedLanguage!,
      );

      await FirebaseFirestore.instance
          .collection('text_to_text')
          .doc(userUid)
          .collection('messages')
          .add({
        'message': text,
        'translation': translation,
        'date': FieldValue.serverTimestamp(),
      });

      setState(() {
        _messages.add({
          'user': text,
          'translation': translation,
        });
        _textController.clear();
      });

      // Scroll to the bottom after adding a new message
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'user': text,
          'translation': 'Error unable to translate text',
        });
        print('Error: $e');
      });
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Text Translation',
        ),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 25),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('text_to_text')
                  .doc(widget.userUid)
                  .collection('messages')
                  .orderBy('date', descending: false) // Ensure ascending order
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Start translating'),
                  );
                }

                final messages = snapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController, // Attach ScrollController
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final userMessage = message['message'] as String;
                    final translation = message['translation'] as String;
                    final timestamp = message['date'] as Timestamp?;
                    final formattedDate = timestamp != null
                        ? DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate())
                        : 'Unknown Date';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ChatBubble(
                            text: userMessage,
                            color: Colors.blue[100]!,
                            isUser: true,
                            onDelete: () => deleteTextTranslations(
                              message.id,
                              widget.userUid!,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ChatBubble(
                            text: translation,
                            color: Colors.green[100]!,
                            isUser: false,
                            onDelete: () => deleteTextTranslations(
                              message.id,
                              widget.userUid!,
                            ),
                          ),
                        ),
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
                  onLanguageSelected: (String languageCode) {
                    setState(() {
                      _selectedLanguage = languageCode;
                    });
                  },
                  fillColor: Colors.white,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          labelText: 'Enter text',
                          border: OutlineInputBorder(),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _isTranslating ? null : () => _translateText(widget.userUid!),
                      icon: _isTranslating
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            )
                          : const Icon(Icons.send, color: Colors.blue),
                      tooltip: 'Send',
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