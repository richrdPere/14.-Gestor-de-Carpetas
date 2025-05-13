import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

// Models
import '../models/folder_model.dart';

// Services
import 'package:app_carpetas/services/FolderService.dart';

// Screens
import 'package:app_carpetas/screens/PhotoCaptureScreen.dart';
import 'package:app_carpetas/screens/FolderDetailScreen.dart';

class CreateFolderScreen extends StatefulWidget {
  const CreateFolderScreen({super.key});

  @override
  State<CreateFolderScreen> createState() => _CreateFolderScreenState();
}

class _CreateFolderScreenState extends State<CreateFolderScreen> {
  final FolderService _folderService = FolderService();
  String? error;
  List<FolderModel> folders = [];

  final TextEditingController _folderNameController = TextEditingController();

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
    final loadedFolders = await _folderService.listFolders();
    setState(() {
      folders = loadedFolders;
    });
  }

  Future<void> _createFolder() async {
    final name = _folderNameController.text.trim();
    if (name.isEmpty) {
      setState(() => error = "El nombre no puede estar vacío.");
      return;
    }

    // await _requestPermissions();

    try {
      await _folderService.createFolder(name);

      if (!mounted) return;
      _folderNameController.clear();

      setState(() => error = null);
      await _loadFolders();
    } catch (e) {
      setState(() => error = "Error al crear carpeta: $e");
    }
  }

  // Future<void> _createFolder() async {
  //   final name = _folderNameController.text.trim();

  //   if (name.isEmpty) {
  //     setState(() => error = "El nombre no puede estar vacío.");
  //     return;
  //   }

  //   await _requestPermissions();

  //   try {
  //     final folder = await _folderService.createFolder(name);
  //     if (!mounted) return;
  //     _folderNameController.clear();
  //     setState(() => error = null);
  //     await _loadFolders();

  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) => PhotoCaptureScreen(
  //           folderPath: folder.path,
  //           folderName: name,
  //         ),
  //       ),
  //     );
  //   } catch (e) {
  //     setState(() => error = "Error al crear carpeta: $e");
  //   }
  // }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy – HH:mm').format(date);
  }

  Future<int> _getPhotoCount(String folderPath) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) return 0;
    final files = await dir.list().toList();
    return files.where((f) => f is File && f.path.endsWith(".jpg")).length;
  }

  void _openFolder(FolderModel folder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FolderDetailScreen(
          folderPath: folder.path,
          folderName: folder.name,
          //folderName: folder.path.split('/').last,
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _folderNameController,
                decoration: InputDecoration(
                  labelText: "Nombre de carpeta",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.create_new_folder),
                    onPressed: _createFolder,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            // ElevatedButton.icon(
            //   onPressed: _createFolder,
            //   icon: const Icon(Icons.folder_open),
            //   label: const Text("Crear y continuar"),
            // ),
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
                        final folderName = folder.name;
                        final creationDate = folder.creationDate;

                        return FutureBuilder<int>(
                          future: _getPhotoCount(folder.path),
                          builder: (context, snapshot) {
                            final photoCount = snapshot.data ?? 0;
                            return ListTile(
                              leading:
                                  const Icon(Icons.folder, color: Colors.blue),
                              title: Text(folderName),
                              subtitle: Text(
                                " ${_formatDate(creationDate)}\n $photoCount fotos",
                                style: const TextStyle(height: 1.4),
                              ),
                              isThreeLine: true,
                              onTap: () =>
                                  _openFolder(folder), // ← esto es clave
                            );
                          },
                        );

                        // return ListTile(
                        //   title: Text(folder.name),
                        //   subtitle: Text(
                        //     "📅 ${_formatDate(folder.creationDate)}\n📸 0 fotos",
                        //     style: const TextStyle(height: 1.4),
                        //   ),
                        //   trailing: const Icon(Icons.folder),
                        // );
                      },
                    ),
              // child: folders.isEmpty
              //     ? const Text("No hay carpetas creadas.")
              //     : ListView.builder(
              //         itemCount: folders.length,
              //         itemBuilder: (context, index) {
              //           final folder = folders[index];
              //           final folderName = folder.path.split('/').last;
              //           final creationDate = folder.statSync().modified;

              //           return FutureBuilder<int>(
              //             future: _getPhotoCount(folder.path),
              //             builder: (context, snapshot) {
              //               final photoCount = snapshot.data ?? 0;
              //               return ListTile(
              //                 leading:
              //                     const Icon(Icons.folder, color: Colors.blue),
              //                 title: Text(folderName),
              //                 subtitle: Text(
              //                   "📅 ${_formatDate(creationDate)}\n📸 $photoCount fotos",
              //                   style: const TextStyle(height: 1.4),
              //                 ),
              //                 isThreeLine: true,
              //                 onTap: () => _openFolder(folder),
              //               );
              //             },
              //           );
              //         },
              //       ),
            ),
          ],
        ),
      ),
    );
  }
}
