import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String text;

  const CustomButton({
    Key? key,
    required this.text,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 62, 68, 65), // Button color
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
        width: double.infinity, // Full-width button
        height: 60, // Button height
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white, // Text color
              fontSize: 18, // Font size
              fontWeight: FontWeight.bold, // Bold text
            ),
          ),
        ),
      ),
    );
  }
}
