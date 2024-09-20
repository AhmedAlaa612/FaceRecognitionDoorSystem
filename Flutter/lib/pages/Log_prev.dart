import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImagePreviewPage extends StatelessWidget {
  final dynamic content; // Can be either a String (URL) or Uint8List
  final String description;

  const ImagePreviewPage({
    Key? key,
    required this.content,
    required this.description,
  }) : super(key: key);


  bool get isImageBytes => content is Uint8List; // Check if the content is Uint8List

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Preview'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isImageBytes)
              Image.memory(
                content as Uint8List, // Display image from Uint8List
                width: 300,
                height: 400,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Failed to load image from bytes');
                },
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  content.toString(), // Handle non-image content (String or other types)
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),
            Text(
              description,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
