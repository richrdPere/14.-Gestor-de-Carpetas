import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class PhotoService {
  final ImagePicker _picker = ImagePicker();

  Future<void> captureAndSavePhoto(String folderPath) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newImagePath = p.join(folderPath, 'photo_$timestamp.jpg');
    await File(image.path).copy(newImagePath);

    final position = await Geolocator.getCurrentPosition();
    final metadata = {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': DateTime.now().toIso8601String()
    };

    final metadataPath = p.join(folderPath, 'photo_$timestamp.json');
    await File(metadataPath).writeAsString(jsonEncode(metadata));
  }
}
