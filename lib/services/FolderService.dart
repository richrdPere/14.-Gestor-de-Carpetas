import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FolderService {
  // Crea una carpeta
  static Future<Directory> createFolder(String folderName) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final folderPath = Directory(p.join(baseDir.path, folderName));

    if (!(await folderPath.exists())) {
      await folderPath.create(recursive: true);
    }

    return folderPath;
  }

  // Obtiene todos los directorios creados
  static Future<List<Directory>> getFolders() async {
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
