import 'package:flutter/material.dart';

class ImageButton extends StatelessWidget {
  final String imagePath; // Path to the image
  final VoidCallback onPressed; // Callback for button press
  final double width; // Width of the button
  final double height; // Height of the button
  final double borderRadius; // Border radius for rounded corners

  const ImageButton({
    super.key,
    required this.imagePath,
    required this.onPressed,
    this.width = 100,
    this.height = 100,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2), // Shadow position
            ),
          ],
        ),
      ),
    );
  }
}
