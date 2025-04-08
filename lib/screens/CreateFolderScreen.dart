import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:app_carpetas/services/FolderService.dart';
import 'package:app_carpetas/screens/PhotoCaptureScreen.dart';

class CreateFolderScreen extends StatefulWidget {
  const CreateFolderScreen({super.key});

  @override
  State<CreateFolderScreen> createState() => _CreateFolderScreenState();
}

class _CreateFolderScreenState extends State<CreateFolderScreen> {
  final TextEditingController _controller = TextEditingController();
  String? error;
  List<Directory> folders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.storage, Permission.location]
        .request();
  }

  Future<void> _loadFolders() async {
    final loaded = await FolderService.getFolders();
    setState(() {
      folders = loaded;
    });
  }

  void _createFolder() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => error = "El nombre no puede estar vacío.");
      return;
    }

    await _requestPermissions();

    try {
      final folder = await FolderService.createFolder(name);
      if (!mounted) return;
      _controller.clear();
      setState(() => error = null);
      await _loadFolders();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoCaptureScreen(
            folderPath: folder.path,
            folderName: name,
          ),
        ),
      );
    } catch (e) {
      setState(() => error = "Error al crear carpeta: $e");
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy – HH:mm').format(date);
  }

  Future<int> _getPhotoCount(String folderPath) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) return 0;
    final files = await dir.list().toList();
    return files.where((f) => f is File && f.path.endsWith(".jpg")).length;
  }

  void _openFolder(Directory folder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoCaptureScreen(
          folderPath: folder.path,
          folderName: folder.path.split('/').last,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestión de Carpetas")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Nombre de carpeta",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _createFolder,
              icon: const Icon(Icons.folder_open),
              label: const Text("Crear y continuar"),
            ),
            const SizedBox(height: 24),
            const Text("Carpetas creadas",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: folders.isEmpty
                  ? const Text("No hay carpetas creadas.")
                  : ListView.builder(
                      itemCount: folders.length,
                      itemBuilder: (context, index) {
                        final folder = folders[index];
                        final folderName = folder.path.split('/').last;
                        final creationDate = folder.statSync().modified;

                        return FutureBuilder<int>(
                          future: _getPhotoCount(folder.path),
                          builder: (context, snapshot) {
                            final photoCount = snapshot.data ?? 0;
                            return ListTile(
                              leading:
                                  const Icon(Icons.folder, color: Colors.blue),
                              title: Text(folderName),
                              subtitle: Text(
                                "📅 ${_formatDate(creationDate)}\n📸 $photoCount fotos",
                                style: const TextStyle(height: 1.4),
                              ),
                              isThreeLine: true,
                              onTap: () => _openFolder(folder),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
