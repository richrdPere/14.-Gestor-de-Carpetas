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

  /// 📌 1.- Retorna los datos geográficos actuales + dirección
  Future<Map<String, dynamic>> getGeographicData() async {
    // Obtiene la posición actual con alta precisión
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Convierte latitud y longitud en dirección textual (placemark)
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    final place = placemarks.first;

    final now = DateTime.now();

    return {
      'timestamp': now,
      'position': position,
      'address':
          "${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}",
      'city': place.locality ?? '', // Ciudad (ej. Cusco)
      'district': place.subLocality ?? '', // Distrito (ej. Wanchaq)
      'province': place.subAdministrativeArea ?? '' // Provincia (ej. Cusco)
    };
  }

  /// 📷 2.- Toma la foto, incrusta la marca de agua, y guarda imagen + JSON
  Future<PhotoData?> captureAndSavePhoto(
    String folderPath,
    DateTime timestamp,
    Position position,
  ) async {
    // Obtener datos geográficos detallados
    final geoData = await getGeographicData();
    final DateTime timestamp = geoData['timestamp'];
    final Position position = geoData['position'];
    final String address = geoData['address'];
    final String city = geoData['city'];
    final String district = geoData['district'];
    final String province = geoData['province'];

    // Capturar imagen desde cámara
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
    final String watermarkText =
        "Fecha: ${timestamp.toLocal().toString().split('.').first}\n"
        "Lat: ${position.latitude.toStringAsFixed(6)}\n"
        "Lon: ${position.longitude.toStringAsFixed(6)}\n"
        "Altitud: ${position.altitude.toStringAsFixed(2)} m\n"
        "Ciudad: $city\n"
        "Distrito: $district\n"
        "Provincia: $province\n"
        "Dirección: $address";

    // 🖋️ Dibujar el texto en la imagen
    const int padding = 550;
    final yPos = decodedImage.height - 1050; // Ajustar según altura del texto

    img.drawString(
      decodedImage,
      watermarkText, // El texto debe ser un String
      font:
          bitmapFont, // La fuente BitmapFont debe ser pasada correctamente aquí
      x: padding,
      y: yPos, // Ajusta según tamaño
      color: img.ColorFloat32.rgb(255, 255, 255), // Blanco
      rightJustify: false,
      wrap: true,
    );

    // 💾 Guardar imagen modificada
    final editedBytes = img.encodeJpg(decodedImage);
    await File(newImagePath).writeAsBytes(editedBytes);

    // 📄 Guardar metadata como JSON
    final metadata = {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'altitude': position.altitude,
      'city': city,
      'district': district,
      'province': province,
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
}
