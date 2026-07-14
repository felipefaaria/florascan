import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CameraScreen extends StatelessWidget {
  final VoidCallback onTakePhoto;

  const CameraScreen({super.key, required this.onTakePhoto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 100),
          SizedBox(height: 20),
          ElevatedButton(onPressed: onTakePhoto, child: Text("Tirar Foto")),
        ],
      ),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  final String? lastPhotoPath;

  const DetailsScreen({super.key, this.lastPhotoPath});

  @override
  Widget build(BuildContext context) {
    return Center(
      child:
          lastPhotoPath == null
              ? Text("Nenhuma foto tirada ainda")
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.file(File(lastPhotoPath!), height: 200),
                  SizedBox(height: 20),
                  Text(
                    "Planta X",
                    style: GoogleFonts.lato(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "🌿 Descrição: Lorem Ipsum\n📍 Habitat: Lorem Ipsum\n💧 Cuidados: Lorem Ipsum",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
    );
  }
}
