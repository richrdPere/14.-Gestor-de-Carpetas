import 'package:app_carpetas/services/PhotoService.dart';
import 'package:flutter/material.dart';

class PhotoCaptureScreen extends StatefulWidget {
  final String folderPath;
  final String folderName;

  const PhotoCaptureScreen({
    super.key,
    required this.folderPath,
    required this.folderName,
  });

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  final PhotoService _photoService = PhotoService();
  int photoCount = 0;

  void _takePhoto() async {
    await _photoService.captureAndSavePhoto(widget.folderPath);
    if (!mounted) return; // 👈 Evita el error si el widget ya fue eliminado
    setState(() => photoCount++);
  }

  void _finishAndCreateNewFolder() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Carpeta: ${widget.folderName}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Tomar foto"),
            ),
            const SizedBox(height: 16),
            Text("Fotos tomadas: $photoCount"),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _finishAndCreateNewFolder,
              icon: const Icon(Icons.check),
              label: const Text("Finalizar carpeta"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
