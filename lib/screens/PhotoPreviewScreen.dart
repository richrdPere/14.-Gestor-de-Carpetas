import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Services
import 'package:app_carpetas/services/PhotoService.dart';

// Models
import 'package:app_carpetas/models/PhotoData.dart';

class PhotoPreviewScreen extends StatefulWidget {
  final String folderPath;

  const PhotoPreviewScreen({required this.folderPath});

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  late CameraController _controller;
  Position? _position;
  bool _loading = true;
  String _note = '';

  @override
  void initState() {
    super.initState();
    initCameraAndLocation();
  }

  Future<void> initCameraAndLocation() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras.first, ResolutionPreset.medium);
    await _controller.initialize();

    _position = await Geolocator.getCurrentPosition();

    setState(() {
      _loading = false;
    });
  }

  Future<void> captureAndSavePhoto() async {
    final service = PhotoService();

    final photoData = await service.captureAndSavePhoto(
      widget.folderPath,
      DateTime
          .now(), // puedes enviar el timestamp aquí o dejar que el servicio lo calcule
      _position!,
    );

    if (photoData != null) {
      Navigator.pop(context, true); // indica que se tomó una foto
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo capturar la foto.")),
      );
    }
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
        appBar: AppBar(title: Text("Cargando cámara y GPS")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Previsualización")),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: CameraPreview(_controller),
          ),
          if (_position != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'GPS: ${_position!.latitude}, ${_position!.longitude}',
                style: TextStyle(fontSize: 16),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              decoration: InputDecoration(labelText: 'Agregar una nota'),
              onChanged: (val) => _note = val,
            ),
          ),
          ElevatedButton.icon(
            onPressed: captureAndSavePhoto,
            icon: Icon(Icons.camera_alt),
            label: Text("Tomar foto y guardar"),
          )
        ],
      ),
    );
  }
}
