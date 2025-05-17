import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // <-- Para obtener dirección a partir de coordenadas

// Services
import 'package:app_carpetas/services/PhotoService.dart';

// Models
import 'package:app_carpetas/models/PhotoData.dart';

class PhotoPreviewScreen extends StatefulWidget {
  final String folderPath;

  const PhotoPreviewScreen({super.key, required this.folderPath});

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  late CameraController _controller;
  late List<CameraDescription>? _cameras;
  bool _loading = true;
  bool _isRearCameraSelected = true;
  bool _isRecording = false;
  String _mode = 'Foto';

  Position? _position;
  Placemark? _placemark;

  @override
  void initState() {
    super.initState();
    initCameraAndLocation();
  }

  // 1.- Inicializa la cámara y obtiene ubicación GPS + dirección
  Future<void> initCameraAndLocation() async {
    // Obtiene cámaras disponibles en el dispositivo
    final _cameras = await availableCameras();
    _controller =
        CameraController(_cameras[0], ResolutionPreset.max, enableAudio: true);

    // Usa la primera cámara con resolución media
    _controller = CameraController(_cameras.first, ResolutionPreset.medium);
    await _controller.initialize();

    // Obtiene posición GPS actual con altitud
    _position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Usa la posición GPS para obtener dirección (placemark)
    List<Placemark> placemarks = await placemarkFromCoordinates(
      _position!.latitude,
      _position!.longitude,
    );

    setState(() {
      _placemark = placemarks.first;
      _loading = false;
    });
  }

  // 2.- Captura la foto y llama al servicio para guardarla
  Future<void> captureAndSavePhoto() async {
    final service = PhotoService();

    // Llamamos al servicio, que internamente obtiene:
    final photoData = await service.captureAndSavePhoto(
      widget.folderPath,
      DateTime.now(),
      _position!,
      // Puedes pasar _note, _placemark si modificas el servicio
    );

    if (photoData != null) {
      // Regresamos con éxito
      Navigator.pop(context, true); // Regresa a la pantalla anterior
    } else {
      // Mostramos error en caso de falla
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo capturar la foto.")),
      );
    }
  }

  void _reloadPhotos() {
    // Aquí puedes volver a cargar las fotos desde el folder
    // o hacer un setState si tienes una lista que mostrar
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        // appBar: AppBar(title: Text("Cargando cámara y GPS")),
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Vista previa de cámara
          Positioned.fill(
            child: CameraPreview(_controller),
          ),

          // Texto con coordenadas en blanco (parte inferior derecha)
          Positioned(
            bottom: 100,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: DefaultTextStyle(
                style: TextStyle(color: Colors.white, fontSize: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lat: ${_position?.latitude.toStringAsFixed(5)}'),
                    Text('Lon: ${_position?.longitude.toStringAsFixed(5)}'),
                    Text('Alt: ${_position?.altitude.toStringAsFixed(1)} m'),
                    if (_placemark != null)
                      Text(
                        '${_placemark!.locality}, ${_placemark!.administrativeArea}',
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Botón circular de captura
          Positioned(
            bottom: 30,
            left: MediaQuery.of(context).size.width / 2 - 35,
            child: GestureDetector(
              onTap: () {
                if (_mode == 'Foto') {
                  captureAndSavePhoto();
                }
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
              ),
            ),
          ),

          // Botón de cambio de modo (Foto / Video)
          Positioned(
            bottom: 40,
            left: 20,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _mode = _mode == 'Foto' ? 'Video' : 'Foto';
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _mode,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    // 1.- Prototipo
    // return Scaffold(
    //   // appBar: AppBar(title: Text("Previsualización")),
    //   body: SingleChildScrollView(
    //     child: Column(
    //       children: [
    //         // Vista previa de la cámara
    //         AspectRatio(
    //           aspectRatio: _controller.value.aspectRatio,
    //           child: CameraPreview(_controller),
    //         ),

    //         // Muestra coordenadas GPS y altitud
    //         if (_position != null)
    //           Padding(
    //             padding: const EdgeInsets.all(8.0),
    //             child: Column(
    //               crossAxisAlignment: CrossAxisAlignment.start,
    //               children: [
    //                 Text(
    //                   'Latitud: ${_position!.latitude}',
    //                   style: TextStyle(fontSize: 16),
    //                 ),
    //                 Text(
    //                   'Longitud: ${_position!.longitude}',
    //                   style: TextStyle(fontSize: 16),
    //                 ),
    //                 Text(
    //                   'Altitud: ${_position!.altitude.toStringAsFixed(2)} m',
    //                   style: TextStyle(fontSize: 16),
    //                 ),
    //               ],
    //             ),
    //           ),

    //         // Muestra dirección completa
    //         if (_placemark != null)
    //           Padding(
    //             padding: const EdgeInsets.symmetric(horizontal: 12.0),
    //             child: Column(
    //               crossAxisAlignment: CrossAxisAlignment.start,
    //               children: [
    //                 Text(
    //                   'Dirección: ${_placemark!.street ?? ''}',
    //                   style: TextStyle(fontSize: 16),
    //                 ),
    //                 Text(
    //                   'Distrito: ${_placemark!.subLocality ?? ''}',
    //                   style: TextStyle(fontSize: 16),
    //                 ),
    //                 Text(
    //                   'Ciudad: ${_placemark!.locality ?? ''}',
    //                   style: TextStyle(fontSize: 16),
    //                 ),
    //                 Text(
    //                   'Departamento: ${_placemark!.administrativeArea ?? ''}',
    //                   style: TextStyle(fontSize: 16),
    //                 ),
    //                 Text(
    //                   'País: ${_placemark!.country ?? ''}',
    //                   style: TextStyle(fontSize: 16),
    //                 ),
    //               ],
    //             ),
    //           ),

    //         // Botón para tomar la foto y guardarla
    //         ElevatedButton.icon(
    //           onPressed: captureAndSavePhoto,
    //           icon: Icon(Icons.camera_alt),
    //           label: Text("Tomar foto y guardar"),
    //         ),
    //       ],
    //     ),
    //   ),
    // );
  }
}
