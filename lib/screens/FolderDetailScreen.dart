import 'dart:io';
import 'package:app_carpetas/screens/FullScreenPhotoView.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart'; // ✅ CORRECTO

// import 'package:app_carpetas/models/folder_model.dart';
import 'package:app_carpetas/screens/PhotoPreviewScreen.dart';

class FolderDetailScreen extends StatefulWidget {
  final String folderPath;
  final String folderName;

  const FolderDetailScreen({
    super.key,
    required this.folderPath,
    required this.folderName,
  });

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  List<File> _photos = [];

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final dir = Directory(widget.folderPath);

    if (!await dir.exists()) return;

    final files = await dir.list().toList();

    final images = files
        .where((file) => file is File && file.path.endsWith('.jpg'))
        .map((f) => File(f.path))
        .toList();

    setState(() {
      _photos = images;
    });
  }

  // void navigateToPhotoPreview() async {
  //   final result = await Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => PhotoPreviewScreen(folderPath: widget.folder.path),
  //     ),
  //   );

  //   if (result == true) _loadPhotos(); // refresh list
  // }

  void _deletePhoto(File file) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Eliminar foto?"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Eliminar")),
        ],
      ),
    );

    if (confirm == true) {
      await file.delete();
      _loadPhotos(); // actualizar galería
    }
  }

  void _sharePhoto(File file) {
    ShareParams(
        files: [XFile(file.path)], text: "Compartido desde app_carpetas ");
  }

  void _viewPhoto(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenPhotoView(imageFile: file),
      ),
    );
  }

  Future<void> _openCameraScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoPreviewScreen(folderPath: widget.folderPath),
      ),
    );

    if (result == true) {
      _loadPhotos(); // recarga si se tomó una nueva foto
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // title: Text(widget.folderName),
          title:
              Text("Carpeta: ${widget.folderName} (${_photos.length} fotos)"),
        ),
        body: Column(children: [
          ElevatedButton.icon(
            onPressed: _openCameraScreen,
            icon: Icon(Icons.camera_alt),
            label: Text("Tomar Foto"),
          ),
          Expanded(
            child: _photos.isEmpty
                ? const Center(child: Text("No hay fotos en esta carpeta."))
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                    ),
                    itemCount: _photos.length,
                    itemBuilder: (context, index) {
                      final file = _photos[index];
                      return GestureDetector(
                        onTap: () => _viewPhoto(file),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.file(file, fit: BoxFit.cover),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                color: Colors.black54,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.share,
                                          color: Colors.white, size: 18),
                                      onPressed: () => _sharePhoto(file),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red, size: 18),
                                      onPressed: () => _deletePhoto(file),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          )
        ]));
  }
}

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         // title: Text(widget.folderName),
//         title: Text("Carpeta: ${widget.folderName} (${_photos.length} fotos)"),
//       ),
//       body: Column(
//         children: [
//           ElevatedButton.icon(
//             onPressed: _openCameraScreen,
//             icon: Icon(Icons.camera_alt),
//             label: Text("Tomar Foto"),
//           ),
//           Expanded(
//             child: _photos.isEmpty
//                 ? Center(child: Text("No hay fotos"))
//                 : GridView.builder(
//                     padding: EdgeInsets.all(8),
//                     itemCount: _photos.length,
//                     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: 2,
//                       mainAxisSpacing: 8,
//                       crossAxisSpacing: 8,
//                     ),
//                     itemBuilder: (context, index) {
//                       final photo = _photos[index];
//                       return GestureDetector(
//                         onTap: () {
//                           // puedes agregar aquí una vista completa más adelante
//                         },
//                         child: Image.file(photo, fit: BoxFit.cover),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }
