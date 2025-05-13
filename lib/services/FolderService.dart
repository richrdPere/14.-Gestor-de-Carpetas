import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../models/folder_model.dart';

class FolderService {
  // Crea una carpeta
  Future<FolderModel> createFolder(String folderName) async {
    final Directory baseDir = await getApplicationDocumentsDirectory();

    final String timestamp =
        DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final String folderPath = '${baseDir.path}/$folderName-$timestamp';

    final newFolder = Directory(folderPath);
    if (!(await newFolder.exists())) {
      await newFolder.create(recursive: true);
    }

    return FolderModel(
      name: folderName,
      path: folderPath,
      creationDate: DateTime.now(),
    );
  }

  // Obtiene una lista de todos los folderes creados
  Future<List<FolderModel>> listFolders() async {
    final Directory baseDir = await getApplicationDocumentsDirectory();
    final folders = baseDir.listSync().whereType<Directory>();

    return folders.map((dir) {
      return FolderModel(
        name: p.basename(dir.path),
        path: dir.path,
        creationDate: dir.statSync().changed,
      );
    }).toList();
  }

  // Obtiene todos los directorios creados
  Future<List<Directory>> getFolders() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final dir = Directory(baseDir.path);

    if (await dir.exists()) {
      // Filtramos solo los directorios
      final directories = dir
          .listSync()
          .where((entity) => entity is Directory)
          .map((entity) => entity as Directory)
          .toList();
      return directories;
    } else {
      return [];
    }
  }
}
