import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // 👈 Importante para obtener dirección
import 'package:app_carpetas/services/PhotoService.dart';
import 'package:app_carpetas/models/PhotoData.dart';

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
  List<PhotoData> photos = [];

  DateTime currentTime = DateTime.now();
  Position? currentPosition;
  Timer? _timer;

  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _startClock(); // ⏰ Iniciar reloj en tiempo real
    _getLocation(); // 📍 Obtener ubicación GPS al iniciar
    _initializeCamera();
  }

  /// ⏰ Iniciar el temporizador para actualizar la hora cada segundo
  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => currentTime = DateTime.now());
    });
  }

  /// 📍 Función que solicita permisos y obtiene la ubicación actual
  Future<void> _getLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    if (mounted) {
      setState(() => currentPosition = pos);
    }
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (mounted) {
      setState(() => _isCameraInitialized = true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // ❌ Detener el temporizador al salir de la pantalla
    _cameraController?.dispose();
    super.dispose();
  }

  /// ✅ NUEVO MÉTODO: obtener la hora y geolocalización actual
  // Future<(DateTime, Position)?> getGeographicData() async {
  //   try {
  //     final DateTime now = DateTime.now();
  //     final Position pos = await Geolocator.getCurrentPosition(
  //         desiredAccuracy: LocationAccuracy.high);
  //     return (now, pos); // Devolver tupla con fecha y posición
  //   } catch (e) {
  //     return null;
  //   }
  // }
  Future<String?> getGeographicData(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Devuelve ciudad o distrito
        return "${place.locality}, ${place.subAdministrativeArea}";
      }
    } catch (e) {
      print("Error obteniendo dirección: $e");
    }
    return null;
  }

  /// 📸 Función que toma una foto con timestamp y datos de geolocalización
  Future<void> _takePhoto() async {
    if (!_isCameraInitialized || currentPosition == null) return;

    final image = await _cameraController!.takePicture();
    final file = File(image.path);

    final photoData = await _photoService.captureAndSavePhoto(
      // file,
      widget.folderPath,
      currentTime,
      currentPosition!,
    );

    if (!mounted || photoData == null) return;

    final locationName = await getGeographicData(
      currentPosition!.latitude,
      currentPosition!.longitude,
    );

    final enrichedPhoto = PhotoData(
      imagePath: photoData.imagePath,
      timestamp: photoData.timestamp,
      latitude: photoData.latitude,
      longitude: photoData.longitude,
      locationName: locationName,
    );

    setState(() => photos.add(enrichedPhoto));
    _getLocation(); // Actualiza GPS tras tomar foto
  }

  /*
  Future<void> _takePhoto() async {
    if (currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación aún no disponible')),
      );
      return;
    }

    final photoData = await _photoService.captureAndSavePhoto(
      widget.folderPath,
      currentTime,
      currentPosition!,
    );

    if (!mounted || photoData == null) return;

    // Obtener nombre de la ubicación
    final locationName = await getGeographicData(
      currentPosition!.latitude,
      currentPosition!.longitude,
    );

    // Crear nuevo objeto con ubicación textual
    final enrichedPhoto = PhotoData(
      imagePath: photoData.imagePath,
      timestamp: photoData.timestamp,
      latitude: photoData.latitude,
      longitude: photoData.longitude,
      locationName: locationName,
    );

    setState(() {
      photos.add(enrichedPhoto);
    });

    _getLocation(); // Actualiza la ubicación después de cada foto
  }
  */
  /*
  Future<void> _takePhoto() async {
    final data = await getGeographicData(); // ⏱️📍 Obtener datos actuales

    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener ubicación.')),
      );
      return;
    }

    final (timestamp, position) = data;

    final photoData = await _photoService.captureAndSavePhoto(
      widget.folderPath,
      timestamp,
      position,
    );

    if (!mounted || photoData == null) return;

    setState(() {
      photos.add(photoData);
    });

    _getLocation(); // 🔄 Actualizar GPS después de la foto
  }
  */
  void _finishAndCreateNewFolder() {
    Navigator.pop(context);
  }

  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final gps = currentPosition;
    return Scaffold(
      appBar: AppBar(title: Text("Carpeta: ${widget.folderName}")),
      body: _isCameraInitialized
          ? Stack(
              children: [
                CameraPreview(_cameraController!),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📅 ${_formatDate(currentTime)}",
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white)),
                        const SizedBox(height: 4),
                        if (gps != null)
                          Text(
                            "📍 Lat: ${gps.latitude.toStringAsFixed(6)}  "
                            "Lon: ${gps.longitude.toStringAsFixed(6)}",
                            style: const TextStyle(color: Colors.white),
                          )
                        else
                          const Text("📍 Obteniendo ubicación...",
                              style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Tomar foto"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _finishAndCreateNewFolder,
                        icon: const Icon(Icons.check),
                        label: const Text("Finalizar carpeta"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

/*
  @override
  Widget build(BuildContext context) {
    final gps = currentPosition;
    return Scaffold(
      appBar: AppBar(title: Text("Carpeta: ${widget.folderName}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("📅 ${_formatDate(currentTime)}",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  if (gps != null)
                    Text("📍 Lat: ${gps.latitude.toStringAsFixed(6)}  "
                        "Lon: ${gps.longitude.toStringAsFixed(6)}"),
                  if (gps == null) const Text("📍 Obteniendo ubicación..."),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Tomar foto"),
            ),
            const SizedBox(height: 16),
            Text("Fotos tomadas: ${photos.length}"),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _finishAndCreateNewFolder,
              icon: const Icon(Icons.check),
              label: const Text("Finalizar carpeta"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            const SizedBox(height: 24),
            const Text(
              "Lista de fotos:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: photos.isEmpty
                  ? const Center(child: Text("Aún no has tomado fotos"))
                  : ListView.builder(
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        final photo = photos[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              ListTile(
                                leading: Image.file(
                                  File(photo.imagePath),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                                title: Text("📸 Foto ${index + 1}"),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("🕓 ${_formatDate(photo.timestamp)}"),
                                    const SizedBox(height: 4),
                                    if (photo.locationName != null)
                                      Text("📍 ${photo.locationName!}"),
                                    Text(
                                        "Lat: ${photo.latitude.toStringAsFixed(6)}\n"
                                        "Lon: ${photo.longitude.toStringAsFixed(6)}",
                                        style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  */
