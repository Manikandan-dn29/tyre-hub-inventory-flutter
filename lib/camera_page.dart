import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? image;

  Future<void> openCamera() async {
    final img = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (img != null) {
      setState(() => image = img);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Capture Image")),
      body: Column(
        children: [
          const SizedBox(height: 20),

          image == null
              ? const Icon(Icons.camera_alt, size: 120)
              : Image.file(File(image!.path), height: 300),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            icon: const Icon(Icons.camera),
            label: const Text("Open Camera"),
            onPressed: openCamera,
          ),

          if (image != null)
            ElevatedButton(
              child: const Text("Use This Image"),
              onPressed: () {
                Navigator.pop(context, image);
              },
            )
        ],
      ),
    );
  }
}
