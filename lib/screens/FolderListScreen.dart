import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'PhotoGalleryScreen.dart'; // ⬅ Pantalla que verás después

class FolderListScreen extends StatefulWidget {
  const FolderListScreen({super.key});

  @override
  State<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {
  List<Directory> _folders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final baseDir = await getExternalStorageDirectory();
    final folderRoot = Directory("${baseDir!.path}/MisCarpetas");

    if (await folderRoot.exists()) {
      final folders = folderRoot.listSync().whereType<Directory>().toList();

      setState(() {
        _folders = folders;
      });
    }
  }

  int _countImages(FileSystemEntity folder) {
    final files = Directory(folder.path)
        .listSync()
        .whereType<File>()
        .where((file) =>
            file.path.endsWith(".jpg") ||
            file.path.endsWith(".png") ||
            file.path.endsWith(".jpeg"))
        .toList();
    return files.length;
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy – HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis Carpetas")),
      body: _folders.isEmpty
          ? const Center(child: Text("No hay carpetas aún."))
          : ListView.builder(
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                final folder = _folders[index];
                final name = folder.path.split('/').last;
                final stat = folder.statSync();
                final count = _countImages(folder);

                return ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(name),
                  subtitle: Text(
                    "📅 ${_formatDate(stat.modified)}\n📷 $count fotos",
                  ),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PhotoGalleryScreen(folderPath: folder.path),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
