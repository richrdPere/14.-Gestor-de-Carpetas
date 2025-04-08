import 'dart:io';
import 'package:flutter/material.dart';

class PhotoGalleryScreen extends StatelessWidget {
  final String folderPath;

  const PhotoGalleryScreen({super.key, required this.folderPath});

  @override
  Widget build(BuildContext context) {
    final imageFiles = Directory(folderPath)
        .listSync()
        .whereType<File>()
        .where((file) =>
            file.path.endsWith(".jpg") ||
            file.path.endsWith(".png") ||
            file.path.endsWith(".jpeg"))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Fotos")),
      body: imageFiles.isEmpty
          ? const Center(child: Text("No hay fotos en esta carpeta."))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: imageFiles.length,
              itemBuilder: (context, index) {
                return Image.file(imageFiles[index], fit: BoxFit.cover);
              },
            ),
    );
  }
}
