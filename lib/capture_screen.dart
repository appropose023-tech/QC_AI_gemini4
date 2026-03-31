import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

import 'result_screen.dart';
import 'api_service.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  CameraController? controller;
  bool loading = true;
  XFile? captured;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    final cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.max);
    await controller!.initialize();
    setState(() => loading = false);
  }

  Future<void> captureImage() async {
    if (controller == null || !controller!.value.isInitialized) return;

    final file = await controller!.takePicture();

    setState(() => captured = file);

    // send to server
    final analyzedPath = await ApiService.sendToServer(File(file.path));

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(analyzedPath: analyzedPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Capture PCB")),
      body: Column(
        children: [
          Expanded(child: CameraPreview(controller!)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: captureImage,
              child: const Text("Capture & Analyze"),
            ),
          )
        ],
      ),
    );
  }
}
