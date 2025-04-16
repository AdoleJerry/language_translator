import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final Color color;
  final bool isUser;
  final VoidCallback? onDelete; // Callback for delete action

  const ChatBubble({
    super.key,
    required this.text,
    required this.color,
    required this.isUser,
    this.onDelete, // Optional delete callback
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) async {
        // Show a popup menu with "Copy" and "Delete" options
        final selectedOption = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx, // X position of the press
            details.globalPosition.dy - 50, // Y position above the pressed widget
            MediaQuery.of(context).size.width - details.globalPosition.dx,
            MediaQuery.of(context).size.height - details.globalPosition.dy,
          ),
          items: [
            const PopupMenuItem<String>(
              value: 'copy',
              child: Text('Copy'),
            ),
            if (onDelete != null) // Show "Delete" only if onDelete is provided
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete'),
              ),
          ],
        );

        if (selectedOption == 'copy') {
          // Copy the text to the clipboard
          Clipboard.setData(ClipboardData(text: text)).then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Text copied to clipboard!'),
                duration: Duration(seconds: 2),
              ),
            );
          });
        } else if (selectedOption == 'delete') {
          // Call the delete callback if provided
          if (onDelete != null) {
            onDelete!();
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12.0),
            topRight: const Radius.circular(12.0),
            bottomLeft: isUser ? const Radius.circular(12.0) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(12.0),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}