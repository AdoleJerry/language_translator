import 'package:final_year_project/custom_widgets/chatbubble.dart';
import 'package:final_year_project/custom_widgets/supportedlanaguages.dart';
import 'package:flutter/material.dart';
import '../functions/functions.dart';

class TextChatbox extends StatefulWidget {
  const TextChatbox({super.key});

  @override
  TextChatboxState createState() => TextChatboxState();
}

class TextChatboxState extends State<TextChatbox> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _messages = []; // Stores user input and translations
  String? _selectedLanguage; // Default to null to ensure validation
  bool _isTranslating = false;
  final GoogleTranslationService _translationService;

  TextChatboxState()
      : _translationService =
            GoogleTranslationService('AIzaSyDc764MUCS1t8YulQ5RX686HEb3rq0WytM');

  Future<void> _translateText() async {
    final text = _textController.text.trim();
    // Validation: Check if the text field is empty or no language is selected
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

      setState(() {
        _messages.add({
          'user': text, // User's input
          'translation': translation, // Translated text
        });
        _textController.clear();
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'user': text,
          'translation': 'Error: $e',
        });
      });
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (message['user'] != null)
                      Align(
                        alignment: Alignment.centerRight, // User's text on the right
                        child: ChatBubble(
                          text: message['user']!,
                          color: Colors.blue[100]!,
                          isUser: true,
                        ),
                      ),
                    if (message['translation'] != null)
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
      onPressed: _isTranslating ? null : _translateText,
      icon: _isTranslating
          ? const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            )
          : const Icon(Icons.send, color: Colors.blue),
      tooltip: 'Send', // Tooltip for accessibility
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