import 'package:flutter/material.dart';

class LanguageDropdown extends StatefulWidget {
  final Function(String) onLanguageSelected;
  final Color fillColor;

  const LanguageDropdown({
    super.key,
    required this.onLanguageSelected,
    required this.fillColor,
  });

  @override
  LanguageDropdownState createState() => LanguageDropdownState();
}

class LanguageDropdownState extends State<LanguageDropdown> {
  // List of language names
  final List<String> _languageNames = [
    'English',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Hausa',
    'Igbo',
    'Yoruba',
  ];

  // Corresponding list of language codes
  final List<String> _languageCodes = [
    'en',
    'es',
    'fr',
    'de',
    'zh',
    'ha',
    'ig',
    'yo',
  ];

  String? _selectedLanguageCode;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: DropdownButtonFormField<String>(
        value: _selectedLanguageCode,
        icon: const Icon(Icons.language, color: Colors.blue),
        dropdownColor: widget.fillColor,
        hint: const Text('Select a Language'),
        items: List.generate(_languageNames.length, (index) {
          return DropdownMenuItem<String>(
            value: _languageCodes[index], // Use the language code as the value
            child: Text(_languageNames[index]), // Display the language name
          );
        }),
        onChanged: (String? newValue) {
          setState(() {
            _selectedLanguageCode = newValue;
          });
          if (newValue != null) {
            widget.onLanguageSelected(
                newValue); // Pass the selected language code
          }
        },
      ),
    );
  }
}
