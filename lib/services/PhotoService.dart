import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';

import 'package:app_carpetas/models/PhotoData.dart';

class PhotoService {
  final ImagePicker _picker = ImagePicker();

  /// 📌 Retorna los datos geográficos actuales + dirección
  Future<Map<String, dynamic>> getGeographicData() async {
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    final placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    final place = placemarks.first;

    final now = DateTime.now();

    return {
      'timestamp': now,
      'position': position,
      'address':
          "${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}",
    };
  }

  /// 📷 Toma la foto, incrusta la marca de agua, y guarda imagen + JSON
  Future<PhotoData?> captureAndSavePhoto(
    String folderPath,
    DateTime timestamp,
    Position position,
  ) async {
    final geoData = await getGeographicData();
    final DateTime timestamp = geoData['timestamp'];
    final Position position = geoData['position'];
    final String address = geoData['address'];

    // Capturar imagen
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;

    final timestampMillis = timestamp.millisecondsSinceEpoch;
    final newImagePath = p.join(folderPath, 'photo_$timestampMillis.jpg');

    final originalBytes = await File(image.path).readAsBytes();
    final decodedImage = img.decodeImage(originalBytes);

    if (decodedImage == null) return null;

    // ✅ Cargar fuente tipo bitmap desde .fnt y .png
    final fontFnt = await rootBundle.loadString('assets/fonts/Arial.fnt');
    final fontPng = await rootBundle.load('assets/fonts/Arial.png');
    final fontImage = img.decodeImage(fontPng.buffer.asUint8List());

    // Preprocesar el archivo .fnt para convertir los valores decimales
    final processedFontFnt = fontFnt.replaceAllMapped(
      RegExp(r"(-?\d*\.\d+)"),
      (match) => double.parse(match.group(0)!)
          .round() // Redondear al entero más cercano
          .toString(),
    );

    // Cargar la fuente bitmap con los valores procesados
    final bitmapFont = img.BitmapFont.fromFnt(processedFontFnt, fontImage!);

    // 📍 Preparar texto con timestamp y geolocalización
    final watermarkText = "${timestamp.toLocal().toString().split('.').first}\n"
        "Lat: ${position.latitude.toStringAsFixed(6)}\n"
        "Lon: ${position.longitude.toStringAsFixed(6)}\n"
        "Altitud: ${position.altitude.toStringAsFixed(2)} m\n"
        "$address";

    // 🖋️ Dibujar el texto en la imagen
    img.drawString(
      decodedImage,
      watermarkText, // El texto debe ser un String
      font:
          bitmapFont, // La fuente BitmapFont debe ser pasada correctamente aquí
      x: 20,
      y: decodedImage.height - 70, // Ajusta según tamaño
    );

    // 💾 Guardar imagen modificada
    final editedBytes = img.encodeJpg(decodedImage);
    await File(newImagePath).writeAsBytes(editedBytes);

    // 📄 Guardar metadata como JSON
    final metadata = {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'altitude': position.altitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
    };
    final metadataPath = p.join(folderPath, 'photo_$timestampMillis.json');
    await File(metadataPath).writeAsString(jsonEncode(metadata));

    return PhotoData(
      imagePath: newImagePath,
      timestamp: timestamp,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
/*
  Future<PhotoData?> captureAndSavePhoto(
      String folderPath, DateTime timestamp, Position position) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image == null) return null;

    // Datos georeferenciales
    final timestampMillis = timestamp.millisecondsSinceEpoch;
    final newImagePath = p.join(folderPath, 'photo_$timestampMillis.jpg');
    await File(image.path).copy(newImagePath);

    final metadata = {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': timestamp.toIso8601String(),
    };

    final metadataPath = p.join(folderPath, 'photo_$timestampMillis.json');
    await File(metadataPath).writeAsString(jsonEncode(metadata));

    return PhotoData(
      imagePath: newImagePath,
      timestamp: timestamp,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
*/
}
