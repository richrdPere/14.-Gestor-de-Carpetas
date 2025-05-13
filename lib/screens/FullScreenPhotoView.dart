import 'dart:io';
import 'package:flutter/material.dart';

class FullScreenPhotoView extends StatelessWidget {
  final File imageFile;

  const FullScreenPhotoView({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: Image.file(imageFile),
      ),
    );
  }
}
